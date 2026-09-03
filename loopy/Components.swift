//
//  Components.swift
//  loopy
//
//  Reusable building blocks in the monochrome "warm paper" style.
//

import SwiftUI

// MARK: - Eyebrow / labels

struct Eyebrow: View {
    let text: String
    var color: Color = Theme.eyebrow
    var body: some View {
        Text(text.uppercased())
            .font(.pro(11, .regular))
            .tracking(2.4)
            .foregroundStyle(color)
    }
}

// MARK: - Rules

struct StrongRule: View {
    var body: some View { Rectangle().fill(Theme.ink).frame(height: 1.5) }
}
struct Hairline: View {
    var body: some View { Rectangle().fill(Theme.line).frame(height: 1.5) }
}

// MARK: - Buttons

struct FilledPill: View {
    let title: String
    var icon: String? = nil
    var enabled: Bool = true
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).font(.pro(15, .medium)) }
                Text(title).font(.pro(16, .medium)).tracking(0.2)
            }
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(Theme.ink))
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
    }
}

struct OutlinePill: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).font(.pro(14, .medium)) }
                Text(title).font(.pro(16, .medium))
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 1.5))
        }
        .buttonStyle(PressableStyle())
    }
}

// Legacy aliases so older call sites keep compiling.
typealias PrimaryButton = FilledPillCompat
struct FilledPillCompat: View {
    let title: String
    var icon: String? = nil
    var gradient: Int? = nil
    var foreground: Color = .clear
    var enabled: Bool = true
    let action: () -> Void
    init(title: String, icon: String? = nil, enabled: Bool = true, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.enabled = enabled; self.action = action
    }
    var body: some View { FilledPill(title: title, icon: icon, enabled: enabled, action: action) }
}
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var body: some View { OutlinePill(title: title, icon: icon, action: action) }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Live indicator pill

struct LivePill: View {
    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(Theme.ink).frame(width: 7, height: 7)
            Text("LIVE").font(.pro(11, .regular)).tracking(1.6)
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 11).padding(.vertical, 6)
        .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 1.5))
    }
}

// MARK: - Stat block (big number + caption)

struct StatBlock: View {
    let value: String
    var unit: String? = nil
    let caption: String
    var alignment: HorizontalAlignment = .leading
    var body: some View {
        VStack(alignment: alignment, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.display(26)).tracking(-0.4).foregroundStyle(Theme.ink)
                if let unit { Text(unit).font(.pro(15)).foregroundStyle(Theme.secondary) }
            }
            Text(caption).font(.pro(12)).tracking(0.3).foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
    }
}

// MARK: - Exercise line icon

struct ExerciseIcon: View {
    let exercise: ExerciseType
    var size: CGFloat = 30
    var color: Color = Theme.ink
    var body: some View {
        Image(systemName: exercise.symbol)
            .font(.system(size: size, weight: .light))
            .foregroundStyle(color)
            .frame(width: size + 4, height: size + 4)
    }
}

// MARK: - Section header (legacy compatibility)

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"
    var body: some View {
        HStack {
            Text(title).font(.display(19)).foregroundStyle(Theme.ink)
            Spacer()
            if let action {
                Button(actionLabel, action: action).font(.pro(13)).foregroundStyle(Theme.secondary)
            }
        }
    }
}

// MARK: - Progress ring (kept minimal, ink stroke)

struct RingProgress: View {
    var progress: Double
    var lineWidth: CGFloat = 3
    var body: some View {
        ZStack {
            Circle().stroke(Theme.line, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: progress)
        }
    }
}

// MARK: - App glyph (monochrome, bordered)

struct AppGlyph: View {
    let app: LockedApp
    var size: CGFloat = 46
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .strokeBorder(Theme.ink, lineWidth: 1.5)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: app.symbol)
                    .font(.system(size: size * 0.42, weight: .light))
                    .foregroundStyle(Theme.ink)
            )
    }
}

// MARK: - Toggle switch matching the reference

struct LoopToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Theme.ink : Color.clear)
                    .overlay(Capsule().strokeBorder(isOn ? Color.clear : Theme.hairline, lineWidth: 1.5))
                    .frame(width: 46, height: 28)
                Circle()
                    .fill(isOn ? Theme.bg : Theme.hairline)
                    .frame(width: 22, height: 22)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stepper (−/+ circles)

struct CircleStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var body: some View {
        HStack(spacing: 16) {
            stepButton("minus") { value = max(range.lowerBound, value - step) }
            Text("\(value)").font(.pro(16)).foregroundStyle(Theme.ink)
                .frame(minWidth: 26)
                .contentTransition(.numericText())
            stepButton("plus") { value = min(range.upperBound, value + step) }
        }
    }
    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); withAnimation(.easeOut(duration: 0.15)) { action() } } label: {
            Image(systemName: icon).font(.system(size: 15, weight: .regular)).foregroundStyle(Theme.ink)
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setting row

struct SettingRow<Trailing: View>: View {
    let title: String
    var muted: Bool = false
    var showRule: Bool = true
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.pro(16)).foregroundStyle(muted ? Theme.secondary : Theme.ink)
                Spacer()
                trailing()
            }
            .padding(.vertical, 15)
            if showRule { Rectangle().fill(Theme.line).frame(height: 1.5) }
        }
    }
}

// MARK: - Chevron

struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.tertiary)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 34, weight: .light)).foregroundStyle(Theme.tertiary)
            Text(title).font(.display(19)).foregroundStyle(Theme.ink)
            Text(message).font(.pro(15)).foregroundStyle(Theme.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 34)
    }
}

// MARK: - Text field (light)

struct LoopTextField: View {
    let placeholder: String
    var icon: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    @Binding var text: String
    @State private var reveal = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .light))
                .foregroundStyle(Theme.secondary).frame(width: 22)
            Group {
                if isSecure && !reveal {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.tertiary))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.tertiary))
                }
            }
            .font(.pro(16))
            .foregroundStyle(Theme.ink)
            .tint(Theme.ink)
            .keyboardType(keyboard)
            .textContentType(textContentType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
            if isSecure {
                Button { reveal.toggle() } label: {
                    Image(systemName: reveal ? "eye.slash" : "eye").foregroundStyle(Theme.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 54)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1.5) }
    }
}
