import Foundation

// MARK: - Level
struct Level: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var levelNumber: Int
    var name: String
    var pointsRequired: Int
    var nextMilestone: String
}

// MARK: - Milestone
struct Milestone: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var pointsRequired: Int
    var imageUrl: String
}

// MARK: - UserMilestone
struct UserMilestone: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var milestoneId: UUID
    var progress: Int
    var achievedAt: Date?
}

// MARK: - DailyTip
struct DailyTip: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var content: String
    var isActive: Bool
}
