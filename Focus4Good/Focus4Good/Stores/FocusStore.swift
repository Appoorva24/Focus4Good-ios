import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class FocusStore {

    // MARK: - State
    var sessions: [FocusSession] = []
    var activeSession: FocusSession?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
    var completedSessions: [FocusSession] { sessions.filter { $0.status == .completed } }
    var totalFocusMinutes: Int { completedSessions.reduce(0) { $0 + $1.focusDurationMinutes } }
    var todaysSessions: [FocusSession] {
        completedSessions.filter { $0.completedAt.map { Calendar.current.isDateInToday($0) } ?? false }
    }

    static let shared = FocusStore()
    private init() {}

    func fetchSessions(userId: UUID) async {
        isLoading = true
        isLoading = false
    }

    func recordCompletedSession(userId: UUID, taskId: UUID?, focusDuration: Int, distractionCount: Int, pointsEarned: Int) async {
        let session = FocusSession(
            userId: userId,
            taskId: taskId,
            sessionNumber: sessions.count + 1,
            totalSessions: 1,
            focusDurationMinutes: focusDuration,
            breakDurationMinutes: 5,
            distractionCount: distractionCount,
            pointsEarned: pointsEarned,
            status: .completed,
            startedAt: Date(),
            completedAt: Date()
        )
        sessions.append(session)
    }
}
