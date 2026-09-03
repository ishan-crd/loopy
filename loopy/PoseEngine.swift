//
//  PoseEngine.swift
//  loopy
//
//  Camera capture + Vision body-pose detection + rep counting.
//  Push-ups are counted from elbow angle, squats from knee angle.
//

import SwiftUI
import AVFoundation
import Vision
import Observation

// MARK: - Joints we care about

enum Joint: String, CaseIterable {
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
    case neck, root

    var vnName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .leftShoulder:  return .leftShoulder
        case .rightShoulder: return .rightShoulder
        case .leftElbow:     return .leftElbow
        case .rightElbow:    return .rightElbow
        case .leftWrist:     return .leftWrist
        case .rightWrist:    return .rightWrist
        case .leftHip:       return .leftHip
        case .rightHip:      return .rightHip
        case .leftKnee:      return .leftKnee
        case .rightKnee:     return .rightKnee
        case .leftAnkle:     return .leftAnkle
        case .rightAnkle:    return .rightAnkle
        case .neck:          return .neck
        case .root:          return .root
        }
    }
}

/// Skeleton bones to draw.
let skeletonBones: [(Joint, Joint)] = [
    (.neck, .leftShoulder), (.neck, .rightShoulder),
    (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
    (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
    (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
    (.leftHip, .rightHip),
    (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
    (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
]

enum RepPhase: Sendable { case waiting, up, down }

/// Result of processing one frame — Sendable so it can cross to the main actor.
struct PoseResult: Sendable {
    var points: [String: CGPoint]     // Vision-normalized (origin bottom-left)
    var repIncrement: Int
    var phase: RepPhase
    var feedback: String
    var personDetected: Bool
    var depth: Double                 // 0 (standing/up) ... 1 (fully down)
}

// MARK: - Rep counter (runs on the capture queue only)

struct RepCounter {
    let exercise: ExerciseType
    private var stage: RepPhase = .up
    private var primed = false

    init(exercise: ExerciseType) { self.exercise = exercise }

    // Angle thresholds per exercise.
    private var downThreshold: Double { exercise == .pushups ? 95 : 100 }
    private var upThreshold: Double { exercise == .pushups ? 155 : 160 }

    /// Feeds a joint angle, returns (repCompleted, phase, depth, feedback).
    mutating func feed(angle: Double) -> (Bool, RepPhase, Double, String) {
        let depth = normalizedDepth(angle)
        switch stage {
        case .up, .waiting:
            if angle < downThreshold {
                stage = .down
                primed = true
                return (false, .down, depth, "Now push up 💪")
            }
            return (false, .up, depth, primed ? "Go down again" : "Lower down slowly")
        case .down:
            if angle > upThreshold {
                stage = .up
                return (true, .up, depth, "Nice rep!")
            }
            return (false, .down, depth, "All the way up")
        }
    }

    private func normalizedDepth(_ angle: Double) -> Double {
        let clamped = min(upThreshold, max(downThreshold, angle))
        return 1 - (clamped - downThreshold) / (upThreshold - downThreshold)
    }
}

// MARK: - Geometry helpers

enum PoseMath {
    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let m1 = hypot(v1.dx, v1.dy), m2 = hypot(v2.dx, v2.dy)
        guard m1 > 0, m2 > 0 else { return 180 }
        let cosv = max(-1, min(1, dot / (m1 * m2)))
        return acos(cosv) * 180 / .pi
    }
}

// MARK: - Frame handler (nonisolated capture delegate)

final class FrameHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var counter: RepCounter
    private let exercise: ExerciseType
    private let onResult: @Sendable (PoseResult) -> Void
    private let request = VNDetectHumanBodyPoseRequest()

    init(exercise: ExerciseType, onResult: @escaping @Sendable (PoseResult) -> Void) {
        self.exercise = exercise
        self.counter = RepCounter(exercise: exercise)
        self.onResult = onResult
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .leftMirrored, options: [:])
        do {
            try handler.perform([request])
        } catch { return }

        guard let observation = request.results?.first else {
            onResult(PoseResult(points: [:], repIncrement: 0, phase: .waiting,
                                feedback: "Step into frame", personDetected: false, depth: 0))
            return
        }
        process(observation)
    }

    private func process(_ observation: VNHumanBodyPoseObservation) {
        guard let recognized = try? observation.recognizedPoints(.all) else { return }
        var points: [String: CGPoint] = [:]
        for joint in Joint.allCases {
            if let p = recognized[joint.vnName], p.confidence > 0.15 {
                points[joint.rawValue] = p.location
            }
        }

        // Choose the more confident side for angle measurement.
        let angleValue: Double?
        switch exercise {
        case .pushups:
            angleValue = bestAngle(points, [.leftShoulder, .leftElbow, .leftWrist],
                                   [.rightShoulder, .rightElbow, .rightWrist])
        case .squats:
            angleValue = bestAngle(points, [.leftHip, .leftKnee, .leftAnkle],
                                   [.rightHip, .rightKnee, .rightAnkle])
        }

        guard let angle = angleValue else {
            onResult(PoseResult(points: points, repIncrement: 0, phase: .waiting,
                                feedback: "Get your whole body in frame",
                                personDetected: !points.isEmpty, depth: 0))
            return
        }

        let (completed, phase, depth, feedback) = counter.feed(angle: angle)
        onResult(PoseResult(points: points, repIncrement: completed ? 1 : 0,
                            phase: phase, feedback: feedback,
                            personDetected: true, depth: depth))
    }

    private func bestAngle(_ pts: [String: CGPoint], _ left: [Joint], _ right: [Joint]) -> Double? {
        func compute(_ trio: [Joint]) -> Double? {
            guard let a = pts[trio[0].rawValue], let b = pts[trio[1].rawValue],
                  let c = pts[trio[2].rawValue] else { return nil }
            return PoseMath.angle(a, b, c)
        }
        let l = compute(left), r = compute(right)
        switch (l, r) {
        case let (l?, r?): return (l + r) / 2
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }
}

// MARK: - Pose engine (MainActor, drives the UI)

@MainActor
@Observable
final class PoseEngine {
    let exercise: ExerciseType
    let target: Int

    var reps = 0
    var phase: RepPhase = .waiting
    var feedback = "Getting ready…"
    var personDetected = false
    var depth: Double = 0
    var permissionDenied = false
    var cameraAvailable = true

    /// Latest joints in Vision-normalized coords; the preview view observes this to draw.
    var points: [String: CGPoint] = [:]
    /// Bumped every frame so the skeleton view can redraw.
    var frameTick = 0

    var isComplete: Bool { reps >= target }
    var progress: Double { target > 0 ? min(1, Double(reps) / Double(target)) : 0 }

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "loop.camera.session")
    private let videoQueue = DispatchQueue(label: "loop.camera.video")
    private var handler: FrameHandler?
    private let output = AVCaptureVideoDataOutput()
    private var startDate = Date()

    init(exercise: ExerciseType, target: Int) {
        self.exercise = exercise
        self.target = target
    }

    var elapsedSeconds: Int { Int(Date().timeIntervalSince(startDate)) }

    func start() {
        startDate = Date()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted { self?.configureAndRun() }
                    else { self?.permissionDenied = true }
                }
            }
        default:
            permissionDenied = true
        }
    }

    private func configureAndRun() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            cameraAvailable = false
            feedback = "No camera — use demo mode"
            return
        }
        let handler = FrameHandler(exercise: exercise) { [weak self] result in
            DispatchQueue.main.async { self?.ingest(result) }
        }
        self.handler = handler

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            if let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            self.output.setSampleBufferDelegate(handler, queue: self.videoQueue)
            self.output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    private func ingest(_ result: PoseResult) {
        points = result.points
        personDetected = result.personDetected
        depth = result.depth
        frameTick &+= 1
        if !isComplete {
            phase = result.phase
            feedback = result.feedback
            if result.repIncrement > 0 {
                reps += result.repIncrement
                Haptics.rep()
                if isComplete {
                    feedback = "Challenge complete! 🎉"
                    Haptics.success()
                }
            }
        }
    }

    /// Manual rep for simulator / accessibility fallback.
    func simulateRep() {
        guard !isComplete else { return }
        reps += 1
        Haptics.rep()
        if isComplete { Haptics.success(); feedback = "Challenge complete! 🎉" }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}
