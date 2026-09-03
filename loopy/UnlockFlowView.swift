//
//  UnlockFlowView.swift
//  loopy
//
//  Unlock experience — reference screens 01 Lock → 02 Choose → 03 Rep counter → 04 Unlocked.
//

import SwiftUI
import AVFoundation

struct UnlockFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let app: LockedApp

    enum Step { case lock, choose, workout, success }
    @State private var step: Step = {
        switch ProcessInfo.processInfo.environment["LOOP_STEP"] {
        case "choose": return .choose
        case "workout": return .workout
        case "success": return .success
        case "lock": return .lock
        default:
            return ProcessInfo.processInfo.environment["LOOP_UNLOCK"] == "1" ? .workout : .lock
        }
    }()
    @State private var exercise: ExerciseType
    @State private var completedReps = 0
    @State private var duration = 0

    init(app: LockedApp) {
        self.app = app
        _exercise = State(initialValue: app.exercise)
    }

    private var target: Int { appState.effectiveReps(for: app) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch step {
            case .lock:
                LockScreen(app: app, target: target, exercise: exercise,
                           onStart: { withAnimation { step = .choose } },
                           onCancel: { dismiss() })
            case .choose:
                ChooseExerciseScreen(exercise: $exercise, target: target,
                                     onContinue: { withAnimation { step = .workout } },
                                     onCancel: { dismiss() })
            case .workout:
                RepCounterScreen(app: app, exercise: exercise, target: target) { reps, secs in
                    completedReps = reps; duration = secs
                    appState.completeWorkout(app: app, exercise: exercise, reps: reps, duration: secs)
                    withAnimation { step = .success }
                } onQuit: { dismiss() }
            case .success:
                UnlockedScreen(app: app, exercise: exercise, reps: completedReps,
                               streak: appState.streak) { dismiss() }
            }
        }
    }
}

// MARK: - 01 · Lock

struct LockScreen: View {
    let app: LockedApp
    let target: Int
    let exercise: ExerciseType
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow(text: "Screen time · locked")
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .regular)).foregroundStyle(Theme.secondary)
                }
            }
            .padding(.top, 8)

            Spacer()

            Image(systemName: "lock")
                .font(.system(size: 46, weight: .light)).foregroundStyle(Theme.ink)
                .padding(.bottom, 32)
            Text(app.name).font(.display(42)).tracking(-1.2).foregroundStyle(Theme.ink)
            Text("Locked until you move.\nOne set stands between you and the feed.")
                .font(.pro(15)).foregroundStyle(Theme.secondary).lineSpacing(3)
                .padding(.top, 14)

            Spacer()

            StrongRule().padding(.bottom, 20)
            HStack {
                Text("Unlock goal").font(.pro(13)).foregroundStyle(Theme.secondary)
                Spacer()
                HStack(spacing: 9) {
                    ExerciseIcon(exercise: exercise, size: 20)
                    Text("\(target) \(exercise.title.lowercased())").font(.pro(15)).foregroundStyle(Theme.ink)
                }
            }
            .padding(.bottom, 24)
            FilledPill(title: "Start workout", action: onStart)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}

// MARK: - 02 · Choose exercise

struct ChooseExerciseScreen: View {
    @Binding var exercise: ExerciseType
    let target: Int
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow(text: "Step 1 of 2")
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .regular)).foregroundStyle(Theme.secondary)
                }
            }
            .padding(.top, 8).padding(.bottom, 30)

            Text("Choose your\nunlock").font(.display(29)).tracking(-0.4).foregroundStyle(Theme.ink)
                .lineSpacing(2).padding(.bottom, 28)

            ExerciseChoiceRows(exercise: $exercise, reps: target)

            Spacer()
            FilledPill(title: "Continue", action: onContinue)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}

// MARK: - 03 · Rep counter (camera)

struct RepCounterScreen: View {
    let app: LockedApp
    let exercise: ExerciseType
    let target: Int
    let onComplete: (Int, Int) -> Void
    let onQuit: () -> Void

    @State private var engine: PoseEngine
    @State private var didFinish = false
    @State private var paused = false
    @State private var countdown = 3
    @State private var showCountdown = true

    init(app: LockedApp, exercise: ExerciseType, target: Int,
         onComplete: @escaping (Int, Int) -> Void, onQuit: @escaping () -> Void) {
        self.app = app; self.exercise = exercise; self.target = target
        self.onComplete = onComplete; self.onQuit = onQuit
        _engine = State(initialValue: PoseEngine(exercise: exercise, target: target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(.top, 8).padding(.bottom, 22)
            cameraFrame
            countBlock
            Spacer(minLength: 12)
            controls
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .onAppear { engine.start(); startCountdown() }
        .onDisappear { engine.stop() }
        .onChange(of: engine.reps) { _, _ in checkComplete() }
    }

    private var header: some View {
        HStack {
            Button(action: { engine.stop(); onQuit() }) {
                Image(systemName: "xmark").font(.system(size: 15, weight: .regular)).foregroundStyle(Theme.secondary)
            }
            Spacer()
            Eyebrow(text: exercise.title)
            Spacer()
            LivePill()
        }
    }

    private var cameraFrame: some View {
        ZStack {
            if engine.permissionDenied {
                Rectangle().fill(Theme.surface)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "camera").font(.system(size: 30, weight: .light))
                            Text("Camera off — use the counter below")
                                .font(.pro(12)).multilineTextAlignment(.center)
                        }.foregroundStyle(Theme.secondary).padding(24)
                    )
            } else {
                CameraPoseView(engine: engine)
                    .grayscale(1).contrast(1.04)
            }
            // corner brackets
            CornerBrackets()
            if showCountdown && !engine.permissionDenied {
                ZStack {
                    Color.black.opacity(0.35)
                    Text(countdown > 0 ? "\(countdown)" : "GO")
                        .font(.display(64)).foregroundStyle(.white)
                        .contentTransition(.numericText()).id(countdown)
                }
            }
        }
        .frame(height: 266)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Theme.ink, lineWidth: 1.5))
    }

    private var countBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(String(format: "%02d", engine.reps))
                    .font(.display(76)).tracking(-3).foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text("/ \(target)").font(.pro(24)).foregroundStyle(Theme.secondary)
            }
            .padding(.top, 18)
            // progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line).frame(height: 3)
                    Capsule().fill(Theme.ink).frame(width: geo.size.width * engine.progress, height: 3)
                        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: engine.progress)
                }
            }
            .frame(height: 3).padding(.top, 20)
            Text(engine.feedback).font(.pro(14)).foregroundStyle(Theme.secondary).padding(.top, 16)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if engine.permissionDenied || !engine.cameraAvailable {
                FilledPill(title: "Count a rep", icon: "plus") { engine.simulateRep() }
            }
            OutlinePill(title: paused ? "Resume" : "Pause",
                        icon: paused ? "play.fill" : "pause.fill") {
                paused.toggle()
                if paused { engine.stop() } else { engine.start() }
            }
        }
    }

    private func startCountdown() {
        Task {
            for i in stride(from: 3, through: 0, by: -1) {
                withAnimation { countdown = i }
                try? await Task.sleep(for: .seconds(0.85))
            }
            withAnimation { showCountdown = false }
        }
    }

    private func checkComplete() {
        guard engine.isComplete, !didFinish else { return }
        didFinish = true
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            engine.stop()
            onComplete(engine.reps, engine.elapsedSeconds)
        }
    }
}

struct CornerBrackets: View {
    var body: some View {
        GeometryReader { geo in
            let s: CGFloat = 26, inset: CGFloat = 14, lw: CGFloat = 1.6
            let c = Color.white.opacity(0.9)
            ZStack {
                bracket(c, lw, s).position(x: inset + s/2, y: inset + s/2)
                bracket(c, lw, s).rotationEffect(.degrees(90)).position(x: geo.size.width - inset - s/2, y: inset + s/2)
                bracket(c, lw, s).rotationEffect(.degrees(-90)).position(x: inset + s/2, y: geo.size.height - inset - s/2)
                bracket(c, lw, s).rotationEffect(.degrees(180)).position(x: geo.size.width - inset - s/2, y: geo.size.height - inset - s/2)
            }
        }
    }
    private func bracket(_ color: Color, _ lw: CGFloat, _ s: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: s)); p.addLine(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: s, y: 0))
        }
        .stroke(color, style: StrokeStyle(lineWidth: lw, lineCap: .square))
        .frame(width: s, height: s)
    }
}

// MARK: - 04 · Unlocked

struct UnlockedScreen: View {
    let app: LockedApp
    let exercise: ExerciseType
    let reps: Int
    let streak: Int
    let onDone: () -> Void
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow(text: "Complete")
                Spacer()
            }
            .padding(.top, 8)

            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 56, weight: .light)).foregroundStyle(Theme.ink)
                .padding(.bottom, 30)
                .scaleEffect(appear ? 1 : 0.8).opacity(appear ? 1 : 0)
            Text("Unlocked").font(.display(42)).tracking(-1.2).foregroundStyle(Theme.ink)
            Text("\(reps) \(exercise.title.lowercased()), done clean.\n\(app.name) is open for \(app.unlockMinutes) minutes.")
                .font(.pro(15)).foregroundStyle(Theme.secondary).lineSpacing(3).padding(.top, 14)

            Spacer()

            StrongRule().padding(.bottom, 22)
            HStack {
                StatBlock(value: "\(app.unlockMinutes)", unit: "min", caption: "Time earned")
                StatBlock(value: "\(streak)", unit: streak == 1 ? "day" : "days", caption: "Streak")
            }
            .padding(.bottom, 26)
            FilledPill(title: "Open \(app.name)", action: onDone)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appear = true }
        }
    }
}
