//
//  OnboardingView.swift
//  loopy
//
//  Illustrated intro in the monochrome style.
//

import SwiftUI

private struct OnboardPage {
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @Environment(AppState.self) private var app
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "lock",
                    title: "Your apps,\nlocked by default",
                    subtitle: "Instagram, TikTok, YouTube — the ones that eat your day. Loop puts a gate in front of them."),
        OnboardPage(icon: "figure.strengthtraining.functional",
                    title: "Move to\nunlock",
                    subtitle: "Knock out a set of push-ups or squats. Your camera counts every rep in real time."),
        OnboardPage(icon: "flame",
                    title: "Build a\nstreak",
                    subtitle: "Every unlock is a workout. Watch your reps climb while your screen time drops.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Eyebrow(text: "iOS · Loop")
                Spacer()
                Button("Skip") { finish() }.font(.pro(14)).foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 28).padding(.top, 12)

            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                    pageView(page).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: index)

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Theme.ink : Theme.line)
                        .frame(width: i == index ? 24 : 7, height: 7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
                }
            }
            .padding(.bottom, 24)

            FilledPill(title: index == pages.count - 1 ? "Get started" : "Next",
                       icon: index == pages.count - 1 ? "arrow.right" : nil) {
                if index == pages.count - 1 { finish() } else { withAnimation { index += 1 } }
            }
            .padding(.horizontal, 28).padding(.bottom, 24)
        }
        .loopBackground()
    }

    private func pageView(_ page: OnboardPage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: 68, weight: .ultraLight)).foregroundStyle(Theme.ink)
                .padding(.bottom, 40)
            Text(page.title).font(.display(34)).tracking(-1).foregroundStyle(Theme.ink).lineSpacing(2)
            Text(page.subtitle)
                .font(.pro(16)).foregroundStyle(Theme.secondary).lineSpacing(4)
                .padding(.top, 16).padding(.trailing, 20)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
    }

    private func finish() {
        app.hasOnboarded = true
        app.phase = app.isSignedIn ? .main : .auth
    }
}
