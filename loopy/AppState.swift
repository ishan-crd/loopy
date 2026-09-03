//
//  AppState.swift
//  loopy
//
//  Central source of truth. Persists to UserDefaults so the demo survives relaunch.
//

import SwiftUI
import Observation

enum AppPhase {
    case splash
    case onboarding
    case auth
    case main
}

@Observable
final class AppState {
    // Navigation
    var phase: AppPhase = .splash

    // Persisted state
    var hasOnboarded: Bool { didSet { persist() } }
    var isSignedIn: Bool { didSet { persist() } }
    var user: UserProfile { didSet { persist() } }
    var lockedApps: [LockedApp] { didSet { persist() } }
    var workouts: [WorkoutRecord] { didSet { persist() } }
    var streak: Int { didSet { persist() } }
    var bestStreak: Int { didSet { persist() } }
    var lastActiveDay: Date? { didSet { persist() } }

    // MARK: Init / load

    init() {
        let d = UserDefaults.standard
        hasOnboarded = d.bool(forKey: Keys.onboarded)
        isSignedIn = d.bool(forKey: Keys.signedIn)
        user = AppState.decode(Keys.user, default: .placeholder)
        lockedApps = AppState.decode(Keys.apps, default: AppState.defaultApps())
        workouts = AppState.decode(Keys.workouts, default: [])
        streak = d.integer(forKey: Keys.streak)
        bestStreak = d.integer(forKey: Keys.bestStreak)
        lastActiveDay = d.object(forKey: Keys.lastDay) as? Date

        // QA / demo hook: LOOP_DEMO=1 boots straight into a signed-in main app.
        if ProcessInfo.processInfo.environment["LOOP_DEMO"] == "1" {
            hasOnboarded = true
            isSignedIn = true
            if user.name.isEmpty { user.name = "Ishan" }
            phase = .main
        }
    }

    // MARK: Derived stats

    var totalReps: Int { workouts.reduce(0) { $0 + $1.reps } }
    var totalWorkouts: Int { workouts.count }
    var totalCalories: Double { workouts.reduce(0) { $0 + $1.calories } }

    var repsToday: Int {
        let cal = Calendar.current
        return workouts.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.reps }
    }
    var unlocksToday: Int {
        let cal = Calendar.current
        return workouts.filter { cal.isDateInToday($0.date) }.count
    }
    var repsThisWeek: Int {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())) else { return 0 }
        return workouts.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.reps }
    }
    var goalProgress: Double {
        guard user.dailyRepGoal > 0 else { return 0 }
        return min(1, Double(repsToday) / Double(user.dailyRepGoal))
    }
    var lockedCount: Int { lockedApps.filter { $0.isLocked }.count }

    /// Reps per weekday for the last 7 days (oldest → newest).
    func weeklyReps() -> [(label: String, reps: Int)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEEE"
        var out: [(String, Int)] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let reps = workouts.filter { cal.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.reps }
            out.append((fmt.string(from: day), reps))
        }
        return out
    }

    // MARK: Mutations

    func effectiveReps(for app: LockedApp) -> Int {
        max(1, Int((Double(app.repsRequired) * user.difficulty.multiplier).rounded()))
    }

    func completeWorkout(app: LockedApp, exercise: ExerciseType? = nil, reps: Int, duration: Int) {
        let record = WorkoutRecord(date: Date(), exercise: exercise ?? app.exercise,
                                   reps: reps, appName: app.name, durationSeconds: duration)
        workouts.insert(record, at: 0)
        updateStreak()
        // Temporarily unlock the app.
        if let idx = lockedApps.firstIndex(where: { $0.id == app.id }) {
            lockedApps[idx].isLocked = false
        }
    }

    func relock(_ app: LockedApp) {
        if let idx = lockedApps.firstIndex(where: { $0.id == app.id }) {
            lockedApps[idx].isLocked = true
        }
    }

    func addApp(_ app: LockedApp) { lockedApps.append(app) }
    func removeApp(_ app: LockedApp) { lockedApps.removeAll { $0.id == app.id } }
    func updateApp(_ app: LockedApp) {
        if let idx = lockedApps.firstIndex(where: { $0.id == app.id }) { lockedApps[idx] = app }
    }
    func toggleLock(_ app: LockedApp) {
        if let idx = lockedApps.firstIndex(where: { $0.id == app.id }) {
            lockedApps[idx].isLocked.toggle()
        }
    }

    private func updateStreak() {
        let cal = Calendar.current
        if let last = lastActiveDay {
            if cal.isDateInToday(last) {
                // already counted today
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: Date()),
                      cal.isDate(last, inSameDayAs: yesterday) {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }
        bestStreak = max(bestStreak, streak)
        lastActiveDay = Date()
    }

    func signIn(name: String, email: String) {
        user.name = name.isEmpty ? "Athlete" : name
        user.email = email
        user.joinedAt = Date()
        isSignedIn = true
    }

    func signOut() {
        isSignedIn = false
        phase = .auth
    }

    func resetAll() {
        let d = UserDefaults.standard
        [Keys.onboarded, Keys.signedIn, Keys.user, Keys.apps, Keys.workouts, Keys.streak, Keys.bestStreak, Keys.lastDay]
            .forEach { d.removeObject(forKey: $0) }
        hasOnboarded = false
        isSignedIn = false
        user = .placeholder
        lockedApps = AppState.defaultApps()
        workouts = []
        streak = 0
        bestStreak = 0
        lastActiveDay = nil
        phase = .onboarding
    }

    // MARK: Persistence

    private enum Keys {
        static let onboarded = "loop.onboarded"
        static let signedIn = "loop.signedIn"
        static let user = "loop.user"
        static let apps = "loop.apps"
        static let workouts = "loop.workouts"
        static let streak = "loop.streak"
        static let bestStreak = "loop.bestStreak"
        static let lastDay = "loop.lastDay"
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(hasOnboarded, forKey: Keys.onboarded)
        d.set(isSignedIn, forKey: Keys.signedIn)
        d.set(streak, forKey: Keys.streak)
        d.set(bestStreak, forKey: Keys.bestStreak)
        d.set(lastActiveDay, forKey: Keys.lastDay)
        AppState.encode(user, Keys.user)
        AppState.encode(lockedApps, Keys.apps)
        AppState.encode(workouts, Keys.workouts)
    }

    private static func encode<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private static func decode<T: Decodable>(_ key: String, default def: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: data) else { return def }
        return value
    }

    // MARK: Seed data

    static func defaultApps() -> [LockedApp] {
        [
            AppCatalog.all[0].makeLocked(exercise: .pushups, reps: 10, minutes: 15), // Instagram
            AppCatalog.all[1].makeLocked(exercise: .squats, reps: 15, minutes: 15),  // TikTok
            AppCatalog.all[2].makeLocked(exercise: .pushups, reps: 8, minutes: 20)    // YouTube
        ]
    }
}
