//
//  SettingsView.swift
//  loopy
//
//  Settings (reference screen 06): locked apps + workout config + account.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var editing: LockedApp?
    @State private var showResetConfirm = false

    var body: some View {
        @Bindable var app = app
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings").font(.display(29)).tracking(-0.4).foregroundStyle(Theme.ink)
                    .padding(.bottom, 32)

                // Locked apps
                sectionLabel("Locked apps")
                ForEach(app.lockedApps) { item in
                    appRow(item)
                }
                addAppRow

                // Workout
                sectionLabel("Workout").padding(.top, 30)
                SettingRow(title: "Daily rep goal") {
                    CircleStepper(value: Binding(get: { app.user.dailyRepGoal },
                                                 set: { app.user.dailyRepGoal = $0 }),
                                  range: 10...200, step: 5)
                }
                Button {
                    Haptics.tap()
                    withAnimation { app.user.difficulty = app.user.difficulty.next }
                } label: {
                    SettingRow(title: "Difficulty") {
                        HStack(spacing: 10) {
                            Text(app.user.difficulty.title).font(.pro(15)).foregroundStyle(Theme.secondary)
                            Chevron()
                        }
                    }
                }
                .buttonStyle(PressableStyle())
                SettingRow(title: "Reminders", showRule: false) {
                    LoopToggle(isOn: Binding(get: { app.user.notificationsEnabled },
                                             set: { app.user.notificationsEnabled = $0 }))
                }

                // Account
                sectionLabel("Account").padding(.top, 30)
                SettingRow(title: "Signed in as") {
                    Text(app.user.email.isEmpty ? "alex@loop.app" : app.user.email)
                        .font(.pro(15)).foregroundStyle(Theme.secondary)
                }
                Button { Haptics.tap(); app.signOut() } label: {
                    SettingRow(title: "Sign out") { Chevron() }
                }.buttonStyle(PressableStyle())
                Button { Haptics.warning(); showResetConfirm = true } label: {
                    SettingRow(title: "Reset all data", muted: true, showRule: false) { Chevron() }
                }.buttonStyle(PressableStyle())

                Text("Loop v1.0")
                    .font(.pro(12)).foregroundStyle(Theme.tertiary)
                    .frame(maxWidth: .infinity).padding(.top, 30)
            }
            .padding(.horizontal, 28)
            .padding(.top, 6)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .loopBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .sheet(isPresented: $showAdd) { AddAppSheet() }
        .sheet(item: $editing) { EditAppSheet(app: $0) }
        .confirmationDialog("Reset all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) { app.resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Clears workouts, streak and locked apps.") }
    }

    private func sectionLabel(_ text: String) -> some View {
        Eyebrow(text: text).padding(.bottom, 14)
    }

    private func appRow(_ item: LockedApp) -> some View {
        SettingRow(title: item.name, muted: !item.isLocked) {
            HStack(spacing: 14) {
                Button { Haptics.tap(); editing = item } label: {
                    Image(systemName: "pencil").font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Theme.secondary)
                }
                LoopToggle(isOn: Binding(get: { item.isLocked }, set: { _ in app.toggleLock(item) }))
            }
        }
    }

    private var addAppRow: some View {
        Button { Haptics.tap(); showAdd = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus").font(.system(size: 15, weight: .regular))
                Text("Add app").font(.pro(16))
                Spacer()
            }
            .foregroundStyle(Theme.ink)
            .padding(.vertical, 15)
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Add app catalog

struct AddAppSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    private var available: [CatalogApp] {
        AppCatalog.all.filter { cat in !app.lockedApps.contains { $0.name == cat.name } }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(available) { cat in
                        NavigationLink { ConfigureAppView(catalog: cat) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: cat.symbol).font(.system(size: 18, weight: .light))
                                    .frame(width: 26).foregroundStyle(Theme.ink)
                                Text(cat.name).font(.pro(16)).foregroundStyle(Theme.ink)
                                Spacer()
                                Chevron()
                            }
                            .padding(.vertical, 16)
                            .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1.5) }
                        }
                    }
                    if available.isEmpty {
                        EmptyStateView(icon: "checkmark.circle", title: "All added",
                                       message: "Every app in the catalog is already locked.")
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 28).padding(.top, 8)
            }
            .loopBackground()
            .navigationTitle("Add app").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }.foregroundStyle(Theme.secondary) } }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Configure new app

struct ConfigureAppView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let catalog: CatalogApp
    @State private var exercise: ExerciseType = .pushups
    @State private var reps = 15
    @State private var minutes = 30

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(catalog.name).font(.display(29)).tracking(-0.4).foregroundStyle(Theme.ink)
                    .padding(.top, 8).padding(.bottom, 6)
                Text("Set the challenge to unlock it.").font(.pro(15)).foregroundStyle(Theme.secondary)
                    .padding(.bottom, 28)

                Eyebrow(text: "Exercise").padding(.bottom, 14)
                ExerciseChoiceRows(exercise: $exercise, reps: reps)

                Eyebrow(text: "Settings").padding(.top, 26).padding(.bottom, 4)
                SettingRow(title: "\(exercise.title) goal") {
                    CircleStepper(value: $reps, range: 3...50)
                }
                SettingRow(title: "Unlock duration", showRule: false) {
                    CircleStepper(value: $minutes, range: 5...60, step: 5)
                    // shows minutes
                }

                FilledPill(title: "Lock \(catalog.name)", icon: "lock") {
                    app.addApp(catalog.makeLocked(exercise: exercise, reps: reps, minutes: minutes))
                    Haptics.success(); dismiss()
                }
                .padding(.top, 30)
            }
            .padding(.horizontal, 28).padding(.bottom, 30)
        }
        .loopBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Edit existing app

struct EditAppSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var draft: LockedApp
    @State private var reps: Int
    @State private var minutes: Int

    init(app: LockedApp) {
        _draft = State(initialValue: app)
        _reps = State(initialValue: app.repsRequired)
        _minutes = State(initialValue: app.unlockMinutes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(draft.name).font(.display(29)).tracking(-0.4).foregroundStyle(Theme.ink)
                        .padding(.top, 8).padding(.bottom, 28)

                    Eyebrow(text: "Exercise").padding(.bottom, 14)
                    ExerciseChoiceRows(exercise: $draft.exercise, reps: reps)

                    Eyebrow(text: "Settings").padding(.top, 26).padding(.bottom, 4)
                    SettingRow(title: "\(draft.exercise.title) goal") {
                        CircleStepper(value: $reps, range: 3...50)
                    }
                    SettingRow(title: "Unlock duration", showRule: false) {
                        CircleStepper(value: $minutes, range: 5...60, step: 5)
                    }

                    FilledPill(title: "Save", icon: "checkmark") {
                        draft.repsRequired = reps; draft.unlockMinutes = minutes
                        app.updateApp(draft); Haptics.success(); dismiss()
                    }.padding(.top, 30)

                    Button { app.removeApp(draft); dismiss() } label: {
                        Text("Remove app").font(.pro(15)).foregroundStyle(Theme.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 20)
            }
            .loopBackground()
            .navigationTitle("Edit").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }.foregroundStyle(Theme.secondary) } }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Exercise choice rows (reference screen 02)

struct ExerciseChoiceRows: View {
    @Binding var exercise: ExerciseType
    var reps: Int
    var body: some View {
        VStack(spacing: 16) {
            ForEach(ExerciseType.allCases) { ex in
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { exercise = ex }
                } label: {
                    HStack(spacing: 18) {
                        ExerciseIcon(exercise: ex, size: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ex.title).font(.pro(18, .medium)).foregroundStyle(Theme.ink)
                            Text("\(reps) reps · \(ex == .pushups ? "upper body" : "lower body")")
                                .font(.pro(13)).foregroundStyle(Theme.secondary)
                        }
                        Spacer()
                        if exercise == ex {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 20, weight: .regular)).foregroundStyle(Theme.ink)
                        } else {
                            Chevron()
                        }
                    }
                    .padding(22)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(exercise == ex ? Theme.surface : Color.clear))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(exercise == ex ? Theme.ink : Theme.hairline, lineWidth: 1.5))
                }
                .buttonStyle(PressableStyle())
            }
            HStack(spacing: 9) {
                Image(systemName: "camera").font(.system(size: 15, weight: .light))
                Text("The camera counts your reps automatically.")
                    .font(.pro(13))
            }
            .foregroundStyle(Theme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
    }
}
