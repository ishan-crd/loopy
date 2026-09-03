//
//  SplashView.swift
//  loopy
//
//  Launch screen — thin looping mark on warm paper.
//

import SwiftUI

/// Brand mark — two thin interlocking arcs forming a loop.
struct LoopMark: View {
    var size: CGFloat = 96
    var animated: Bool = false
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.035), lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(spin ? 360 : 0))
            Circle()
                .trim(from: 0, to: 0.42)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.035), lineCap: .round))
                .frame(width: size * 0.58, height: size * 0.58)
                .rotationEffect(.degrees(spin ? -360 : 0))
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

struct SplashView: View {
    @Environment(AppState.self) private var app
    @State private var appear = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                LoopMark(size: 84, animated: true)
                    .opacity(appear ? 1 : 0).scaleEffect(appear ? 1 : 0.7)
                VStack(spacing: 10) {
                    Text("Loop").font(.display(44)).tracking(-1).foregroundStyle(Theme.ink)
                    Text("Earn your screen time")
                        .font(.pro(15)).foregroundStyle(Theme.secondary)
                }
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { appear = true }
            Task {
                try? await Task.sleep(for: .seconds(2.0))
                advance()
            }
        }
    }

    private func advance() {
        if !app.hasOnboarded { app.phase = .onboarding }
        else if !app.isSignedIn { app.phase = .auth }
        else { app.phase = .main }
    }
}
