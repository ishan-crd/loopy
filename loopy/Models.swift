//
//  Models.swift
//  loopy
//
//  Core data models for locked apps, exercises, workouts and the user.
//

import SwiftUI

// MARK: - Exercise

enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case pushups
    case squats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pushups: return "Push-ups"
        case .squats:  return "Squats"
        }
    }
    var singular: String {
        switch self {
        case .pushups: return "push-up"
        case .squats:  return "squat"
        }
    }
    var symbol: String {
        switch self {
        case .pushups: return "figure.strengthtraining.functional"
        case .squats:  return "figure.cross.training"
        }
    }
    var coachingCue: String {
        switch self {
        case .pushups: return "Lower your chest until your elbows bend past 90°, then push all the way up."
        case .squats:  return "Bend your knees until your thighs are parallel, then drive back up."
        }
    }
    /// Approximate calories burned per rep.
    var caloriesPerRep: Double {
        switch self {
        case .pushups: return 0.36
        case .squats:  return 0.32
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy, medium, beast
    var id: String { rawValue }
    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .beast: return "Beast"
        }
    }
    var multiplier: Double {
        switch self {
        case .easy: return 0.6
        case .medium: return 1.0
        case .beast: return 1.6
        }
    }
    var tint: Color { Theme.ink }
    var subtitle: String {
        switch self {
        case .easy: return "Fewer reps to unlock"
        case .medium: return "Balanced challenge"
        case .beast: return "Earn every second"
        }
    }
    var next: Difficulty {
        let all = Difficulty.allCases
        let idx = all.firstIndex(of: self) ?? 0
        return all[(idx + 1) % all.count]
    }
}

// MARK: - Locked app

struct LockedApp: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var symbol: String          // SF Symbol representing the app
    var colorHexTop: UInt
    var colorHexBottom: UInt
    var exercise: ExerciseType
    var repsRequired: Int
    var isLocked: Bool
    /// Minutes granted after completing the challenge.
    var unlockMinutes: Int

    var tint: Color { Color(hex: colorHexTop) }

    var gradient: LinearGradient {
        LinearGradient(colors: [Color(hex: colorHexTop), Color(hex: colorHexBottom)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Catalog of well-known apps

struct CatalogApp: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let top: UInt
    let bottom: UInt

    func makeLocked(exercise: ExerciseType, reps: Int, minutes: Int) -> LockedApp {
        LockedApp(name: name, symbol: symbol, colorHexTop: top, colorHexBottom: bottom,
                  exercise: exercise, repsRequired: reps, isLocked: true, unlockMinutes: minutes)
    }
}

enum AppCatalog {
    static let all: [CatalogApp] = [
        CatalogApp(name: "Instagram", symbol: "camera.fill", top: 0xF9508B, bottom: 0xF9A825),
        CatalogApp(name: "TikTok", symbol: "music.note", top: 0x25F4EE, bottom: 0xFE2C55),
        CatalogApp(name: "YouTube", symbol: "play.rectangle.fill", top: 0xFF4D4D, bottom: 0xB00020),
        CatalogApp(name: "X", symbol: "at", top: 0x2B2B2B, bottom: 0x000000),
        CatalogApp(name: "Reddit", symbol: "antenna.radiowaves.left.and.right", top: 0xFF7A45, bottom: 0xFF4500),
        CatalogApp(name: "Snapchat", symbol: "bolt.fill", top: 0xFFFC00, bottom: 0xF0C000),
        CatalogApp(name: "Facebook", symbol: "person.2.fill", top: 0x4A8BFF, bottom: 0x1877F2),
        CatalogApp(name: "Netflix", symbol: "film.fill", top: 0xE50914, bottom: 0x7A0009),
        CatalogApp(name: "Twitch", symbol: "gamecontroller.fill", top: 0xA970FF, bottom: 0x6441A5),
        CatalogApp(name: "WhatsApp", symbol: "message.fill", top: 0x5DF07A, bottom: 0x25D366),
        CatalogApp(name: "Discord", symbol: "bubble.left.and.bubble.right.fill", top: 0x7C89F5, bottom: 0x5865F2),
        CatalogApp(name: "Pinterest", symbol: "pin.fill", top: 0xFF5C74, bottom: 0xE60023)
    ]
}

// MARK: - Workout record

struct WorkoutRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var exercise: ExerciseType
    var reps: Int
    var appName: String
    var durationSeconds: Int

    var calories: Double { Double(reps) * exercise.caloriesPerRep }
}

// MARK: - User

struct UserProfile: Codable {
    var name: String
    var email: String
    var dailyRepGoal: Int
    var difficulty: Difficulty
    var notificationsEnabled: Bool
    var joinedAt: Date

    static let placeholder = UserProfile(
        name: "", email: "", dailyRepGoal: 50,
        difficulty: .medium, notificationsEnabled: true, joinedAt: Date()
    )
}
