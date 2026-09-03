//
//  AuthView.swift
//  loopy
//
//  Sign up / log in — monochrome, mocked locally.
//

import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var app

    enum Mode { case signUp, logIn }
    @State private var mode: Mode = .signUp
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?

    private var isSignUp: Bool { mode == .signUp }
    private var canSubmit: Bool {
        email.contains("@") && password.count >= 4 && (!isSignUp || !name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LoopMark(size: 56).padding(.top, 30).padding(.bottom, 26)

                Text(isSignUp ? "Create your\naccount" : "Welcome\nback")
                    .font(.display(34)).tracking(-1).foregroundStyle(Theme.ink).lineSpacing(2)
                Text(isSignUp ? "Start turning scroll time into gym time."
                              : "Get back to earning your screen time.")
                    .font(.pro(15)).foregroundStyle(Theme.secondary).padding(.top, 12)

                // Mode switch
                HStack(spacing: 0) {
                    segment("Sign up", .signUp)
                    segment("Log in", .logIn)
                }
                .padding(.top, 30).padding(.bottom, 8)

                VStack(spacing: 4) {
                    if isSignUp {
                        LoopTextField(placeholder: "Name", icon: "person",
                                      textContentType: .name, text: $name)
                    }
                    LoopTextField(placeholder: "Email", icon: "envelope",
                                  keyboard: .emailAddress, textContentType: .emailAddress, text: $email)
                    LoopTextField(placeholder: "Password", icon: "lock",
                                  isSecure: true, textContentType: .password, text: $password)
                }
                .padding(.top, 8)

                if let error {
                    Text(error).font(.pro(13)).foregroundStyle(Theme.ink).padding(.top, 12)
                }

                FilledPill(title: isSignUp ? "Create account" : "Log in",
                           icon: "arrow.right", enabled: canSubmit) { submit() }
                    .padding(.top, 24)

                HStack(spacing: 12) {
                    line; Text("or").font(.pro(13)).foregroundStyle(Theme.tertiary); line
                }
                .padding(.vertical, 22)

                VStack(spacing: 12) {
                    social("apple.logo", "Continue with Apple")
                    social("globe", "Continue with Google")
                }

                Text("By continuing you agree to our Terms & Privacy Policy.")
                    .font(.pro(11)).foregroundStyle(Theme.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 20)
            }
            .padding(.horizontal, 28).padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .loopBackground()
    }

    private var line: some View { Rectangle().fill(Theme.line).frame(height: 1.5) }

    private func segment(_ title: String, _ value: Mode) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { mode = value; error = nil }
        } label: {
            VStack(spacing: 10) {
                Text(title).font(.pro(15, mode == value ? .medium : .regular))
                    .foregroundStyle(mode == value ? Theme.ink : Theme.secondary)
                Rectangle().fill(mode == value ? Theme.ink : Color.clear).frame(height: 1.5)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func social(_ icon: String, _ title: String) -> some View {
        Button {
            Haptics.tap()
            app.signIn(name: isSignUp ? (name.isEmpty ? "Alex" : name) : "Alex",
                       email: email.isEmpty ? "alex@loop.app" : email)
            app.phase = .main
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 17, weight: .light))
                Text(title).font(.pro(16))
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity).frame(height: 54)
            .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 1.5))
        }
        .buttonStyle(PressableStyle())
    }

    private func submit() {
        guard canSubmit else { error = "Please fill in all fields correctly."; return }
        error = nil
        app.signIn(name: name, email: email)
        withAnimation { app.phase = .main }
    }
}
