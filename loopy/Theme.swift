//
//  Theme.swift
//  loopy
//
//  Design system — monochrome "warm paper" aesthetic matching the Loop concept.
//  Bone background, near-black ink, hairline rules, medium-weight display type.
//

import SwiftUI

// MARK: - Palette

enum Theme {
    static let bg = Color(hex: 0xECEBE8)          // screen background (bone)
    static let canvas = Color(hex: 0xC6C5C0)      // outer canvas
    static let ink = Color(hex: 0x16150F)         // primary text / strong rules
    static let surface = Color(hex: 0xE3E2DE)      // filled / selected card
    static let line = Color(hex: 0xD2D1CC)         // hairline divider
    static let hairline = Color(hex: 0xC1C0BA)     // off toggle border
    static let secondary = Color(hex: 0x8B8A83)    // secondary text
    static let tertiary = Color(hex: 0xB4B3AD)     // muted labels
    static let eyebrow = Color(hex: 0x8B8A83)

    // Kept for API compatibility with older call sites.
    static let text = ink
    static let textSecondary = secondary
    static let textTertiary = tertiary
    static let stroke = line
    static let lime = ink
}

// MARK: - Typography (SF Pro Display, medium weight display type)

extension Font {
    /// Display / heading type — medium weight, tight tracking handled at call site.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func pro(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // Legacy aliases used by remaining call sites.
    static func loop(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight)
    }
    static let loopLargeTitle = display(42)
    static let loopTitle = display(29)
    static let loopHeadline = display(20)
    static let loopBody = pro(16)
    static let loopCaption = pro(13)
}

// MARK: - Color hex init

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Background

extension View {
    /// Applies the app's bone background.
    func loopBackground(glow: Bool = false) -> some View {
        self.background(Theme.bg.ignoresSafeArea())
    }

    /// Card container — soft filled surface with hairline border (used sparingly).
    func card(padding: CGFloat = 18, radius: CGFloat = 24, fill: Color = Theme.surface) -> some View {
        self
            .padding(padding)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 1))
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    static func rep() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.85)
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}
