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
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskId = "task_id"
        case sessionNumber = "session_number"
        case totalSessions = "total_sessions"
        case focusDurationMinutes = "focus_duration_minutes"
        case breakDurationMinutes = "break_duration_minutes"
        case distractionCount = "distraction_count"
        case pointsEarned = "points_earned"
        case status
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
    
    enum SessionStatus: String, Codable {
        case inProgress = "in_progress"
        case completed
        case cancelled
    }
}

