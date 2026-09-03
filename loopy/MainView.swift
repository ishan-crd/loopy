//
//  MainView.swift
//  loopy
//
//  App shell: Home hub inside a NavigationStack, Settings pushed from the header.
//

import SwiftUI

struct MainView: View {
    @State private var path: [String] = []
    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Theme.bg, for: .navigationBar)
                .navigationDestination(for: String.self) { _ in SettingsView() }
        }
        .tint(Theme.ink)
        .onAppear {
            if ProcessInfo.processInfo.environment["LOOP_SETTINGS"] == "1", path.isEmpty {
                path = ["settings"]
            }
        }
    }
}
