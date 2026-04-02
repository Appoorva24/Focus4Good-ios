import Foundation


struct FocusSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var taskId: UUID?
    var sessionNumber: Int
    var totalSessions: Int
    var focusDurationMinutes: Int
    var breakDurationMinutes: Int
    var distractionCount: Int
    var pointsEarned: Int
    var status: SessionStatus
    var startedAt: Date
    var completedAt: Date?

    enum SessionStatus: String, Codable {
        case inProgress = "in_progress"
        case completed
        case cancelled
    }
}

