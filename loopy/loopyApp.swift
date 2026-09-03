//
//  loopyApp.swift
//  loopy
//
//  Created by Ishan Gupta on 11/07/26.
//

import SwiftUI

@main
struct loopyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light)
                .tint(Theme.ink)
        }
    }
}
