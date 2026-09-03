//
//  RootView.swift
//  loopy
//
//  Top-level coordinator that swaps between splash, onboarding, auth and main.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            switch app.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .move(edge: .leading)))
            case .auth:
                AuthView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .main:
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: app.phase)
        .onAppear(perform: route)
    }

    private func route() {
        // Splash always shows first; after it, decide where to go.
    }
}
