//
//  CameraPoseView.swift
//  loopy
//
//  Hosts the AVCaptureVideoPreviewLayer and draws the live skeleton overlay,
//  correctly mapped through the preview layer (handles mirroring + aspect fill).
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraPoseView: UIViewRepresentable {
    var engine: PoseEngine

    func makeUIView(context: Context) -> PosePreviewUIView {
        let view = PosePreviewUIView()
        view.configure(session: engine.session)
        return view
    }

    func updateUIView(_ uiView: PosePreviewUIView, context: Context) {
        // frameTick is read so SwiftUI re-invokes this on every processed frame.
        _ = engine.frameTick
        uiView.render(points: engine.points, phase: engine.phase)
    }
}

final class PosePreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private let boneLayer = CAShapeLayer()
    private let jointLayer = CAShapeLayer()

    func configure(session: AVCaptureSession) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        if let conn = previewLayer.connection, conn.isVideoMirroringSupported {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = true
        }
        boneLayer.strokeColor = UIColor.white.cgColor
        boneLayer.lineWidth = 3
        boneLayer.lineCap = .round
        boneLayer.fillColor = UIColor.clear.cgColor
        boneLayer.shadowColor = UIColor.black.cgColor
        boneLayer.shadowRadius = 3
        boneLayer.shadowOpacity = 0.5
        boneLayer.shadowOffset = .zero

        jointLayer.fillColor = UIColor.white.cgColor
        jointLayer.strokeColor = UIColor.white.cgColor
        jointLayer.lineWidth = 1.5

        layer.addSublayer(boneLayer)
        layer.addSublayer(jointLayer)
    }

    /// Converts a Vision-normalized point (origin bottom-left) to a layer point.
    private func layerPoint(_ vision: CGPoint) -> CGPoint {
        // Capture-device space has origin top-left; Vision has origin bottom-left.
        let devicePoint = CGPoint(x: vision.x, y: 1 - vision.y)
        return previewLayer.layerPointConverted(fromCaptureDevicePoint: devicePoint)
    }

    func render(points: [String: CGPoint], phase: RepPhase) {
        guard !points.isEmpty else {
            boneLayer.path = nil
            jointLayer.path = nil
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let bones = UIBezierPath()
        for (a, b) in skeletonBones {
            guard let pa = points[a.rawValue], let pb = points[b.rawValue] else { continue }
            bones.move(to: layerPoint(pa))
            bones.addLine(to: layerPoint(pb))
        }
        boneLayer.path = bones.cgPath

        let alpha: CGFloat = phase == .down ? 0.65 : 1.0
        boneLayer.strokeColor = UIColor.white.withAlphaComponent(alpha).cgColor

        let joints = UIBezierPath()
        for (_, p) in points {
            let c = layerPoint(p)
            joints.append(UIBezierPath(ovalIn: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)))
        }
        jointLayer.path = joints.cgPath

        CATransaction.commit()
    }
}
