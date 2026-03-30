import Foundation

// MARK: - User
struct User: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var fullName: String
    var email: String
    var passwordHash: String?
    var profileImageUrl: String?
    var authProvider: String
    var focusPoints: Int
    var currentLevel: Int
    var bestStreak: Int
    var currentStreak: Int
}

// MARK: - UserSettings
struct UserSettings: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var appNotifications: Bool
    var goalCompletionNotifications: Bool
    var coachingNotifications: Bool
    var timezone: String
}

// MARK: - UserProgress
struct UserProgress: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var periodType: String
    var periodStart: Date
    var tasksCompleted: Int
    var focusTimeMinutes: Int
    var calmCentreMinutes: Int
    var focusPointsEarned: Int
}
