//
//  HomeView.swift
//  loopy
//
//  Home · streak & stats (reference screen 05) plus the locked-apps entry point.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var app
    @State private var challengeApp: LockedApp?

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Late night"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topRow
                streakBlock
                StrongRule().padding(.top, 26).padding(.bottom, 20)
                weekSection
                StrongRule().padding(.top, 24).padding(.bottom, 22)
                summaryRow
                lockedApps
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 28)
            .padding(.top, 6)
        }
        .scrollIndicators(.hidden)
        .loopBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .regular)).foregroundStyle(Theme.ink)
                }
            }
        }
        .fullScreenCover(item: $challengeApp) { UnlockFlowView(app: $0) }
        .onAppear {
            let env = ProcessInfo.processInfo.environment
            if (env["LOOP_UNLOCK"] == "1" || env["LOOP_STEP"] != nil),
               challengeApp == nil, let first = app.lockedApps.first(where: { $0.isLocked }) {
                challengeApp = first
            }
        }
    }

    // MARK: Header

    private var topRow: some View {
        HStack {
            Text("\(greeting), \(app.user.name.isEmpty ? "Alex" : firstName)")
                .font(.pro(15)).foregroundStyle(Theme.ink)
            Spacer()
            Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                .font(.pro(13)).foregroundStyle(Theme.secondary)
        }
        .padding(.bottom, 34)
    }

    private var firstName: String {
        String(app.user.name.split(separator: " ").first ?? "Alex")
    }

    // MARK: Streak

    private var streakBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(app.streak)")
                    .font(.display(96)).tracking(-4).foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Image(systemName: "flame")
                    .font(.system(size: 30, weight: .light)).foregroundStyle(Theme.ink)
                    .padding(.top, 8)
                Spacer()
            }
            Text("Day streak · best is \(max(app.streak, app.bestStreak))")
                .font(.pro(15)).foregroundStyle(Theme.secondary)
        }
    }

    // MARK: This week

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("This week").font(.display(16)).foregroundStyle(Theme.ink)
            let data = app.weeklyReps()
            let maxReps = max(1, data.map(\.reps).max() ?? 1)
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 8) {
                        Text(day.reps > 0 ? "\(day.reps)" : "—")
                            .font(.pro(13, day.reps > 0 ? .medium : .regular))
                            .foregroundStyle(day.reps > 0 ? Theme.ink : Theme.tertiary)
                        Capsule()
                            .fill(day.reps > 0 ? Theme.ink : Theme.line)
                            .frame(width: 2, height: max(5, 40 * CGFloat(day.reps) / CGFloat(maxReps)))
                            .opacity(day.reps > 0 ? 0.85 : 1)
                        Text(day.label)
                            .font(.pro(11)).foregroundStyle(Theme.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: Summary

    private var summaryRow: some View {
        HStack(alignment: .top) {
            StatBlock(value: "\(app.unlocksToday)", caption: "Unlocks today")
            StatBlock(value: "\(app.repsThisWeek)", caption: "Reps this week")
        }
    }

    // MARK: Locked apps entry

    private var lockedApps: some View {
        VStack(alignment: .leading, spacing: 0) {
            StrongRule().padding(.top, 24).padding(.bottom, 18)
            Eyebrow(text: "Locked apps")
                .padding(.bottom, 4)
            if app.lockedApps.isEmpty {
                Text("Add apps in settings to start earning your screen time.")
                    .font(.pro(14)).foregroundStyle(Theme.secondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(app.lockedApps) { item in
                    Button {
                        Haptics.tap()
                        if item.isLocked { challengeApp = item } else { app.relock(item) }
                    } label: { lockedRow(item) }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private func lockedRow(_ item: LockedApp) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: item.isLocked ? "lock" : "lock.open")
                    .font(.system(size: 17, weight: .light)).foregroundStyle(item.isLocked ? Theme.ink : Theme.secondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.pro(16)).foregroundStyle(item.isLocked ? Theme.ink : Theme.secondary)
                    Text("\(app.effectiveReps(for: item)) \(item.exercise.singular)s · \(item.unlockMinutes) min")
                        .font(.pro(12)).foregroundStyle(Theme.tertiary)
                }
                Spacer()
                if item.isLocked {
                    Text("Unlock").font(.pro(14, .medium)).foregroundStyle(Theme.ink)
                    Chevron()
                } else {
                    Text("Open").font(.pro(14, .medium)).foregroundStyle(Theme.secondary)
                }
            }
            .padding(.vertical, 15)
            Rectangle().fill(Theme.line).frame(height: 1.5)
        }
    }
}
