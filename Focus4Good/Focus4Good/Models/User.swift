import Foundation

// MARK: - User (maps to 'profiles' table)
struct User: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var fullName: String
    var email: String
    var profileImageUrl: String?
    var authProvider: String
    var focusPoints: Int
    var currentLevel: Int
    var bestStreak: Int
    var currentStreak: Int
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case profileImageUrl = "profile_image_url"
        case authProvider = "auth_provider"
        case focusPoints = "focus_points"
        case currentLevel = "current_level"
        case bestStreak = "best_streak"
        case currentStreak = "current_streak"
    }
}

// MARK: - UserSettings
struct UserSettings: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var appNotifications: Bool
    var goalCompletionNotifications: Bool
    var coachingNotifications: Bool
    var timezone: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case appNotifications = "app_notifications"
        case goalCompletionNotifications = "goal_completion_notifications"
        case coachingNotifications = "coaching_notifications"
        case timezone
    }
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
    var taskGoal: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case periodType = "period_type"
        case periodStart = "period_start"
        case tasksCompleted = "tasks_completed"
        case focusTimeMinutes = "focus_time_minutes"
        case calmCentreMinutes = "calm_centre_minutes"
        case focusPointsEarned = "focus_points_earned"
        case taskGoal = "task_goal"
    }
}

