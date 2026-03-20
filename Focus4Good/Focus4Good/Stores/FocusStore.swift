import Foundation
import Combine

@MainActor
final class FocusStore: ObservableObject {

    // MARK: - State
    @Published var sessions: [FocusSession] = []
    @Published var activeSession: FocusSession?
    @Published var timeRemaining: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var isBreakTime: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var timerHandle: _Concurrency.Task<Void, Never>?

    // MARK: - Computed
    var completedSessions: [FocusSession] { sessions.filter { $0.status == .completed } }
    var totalFocusMinutes: Int { completedSessions.reduce(0) { $0 + $1.focusDurationMinutes } }
    var totalPointsEarned: Int { completedSessions.reduce(0) { $0 + $1.pointsEarned } }

    var todaysSessions: [FocusSession] {
        completedSessions.filter {
            guard let completedAt = $0.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }
    }

    static let shared = FocusStore()
    private init() {}

    // MARK: - Sessions
    func fetchSessions(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func startSession(userId: UUID, taskId: UUID? = nil, focusDuration: Int = 25, breakDuration: Int = 5, totalSessions: Int = 1) async {
        let sessionNumber = sessions.filter { $0.userId == userId }.count + 1
        let session = FocusSession(
            userId: userId,
            taskId: taskId,
            sessionNumber: sessionNumber,
            totalSessions: totalSessions,
            focusDurationMinutes: focusDuration,
            breakDurationMinutes: breakDuration,
            distractionCount: 0,
            pointsEarned: 0,
            status: .inProgress,
            startedAt: Date(),
            completedAt: nil
        )
        activeSession = session
        sessions.append(session)
        timeRemaining = focusDuration * 60
        isBreakTime = false
        startTimer()
    }

    func logDistraction() {
        guard var session = activeSession else { return }
        session.distractionCount += 1
        activeSession = session
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
    }

    func completeSession() async {
        guard var session = activeSession else { return }
        stopTimer()
        session.status = .completed
        session.completedAt = Date()
        session.pointsEarned = calculatePoints(for: session)
        activeSession = nil
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
        guard let userId = UserStore.shared.currentUser?.id else { return }
        await UserStore.shared.updateFocusPoints(by: session.pointsEarned)
        await ProgressStore.shared.addFocusTime(minutes: session.focusDurationMinutes, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: session.pointsEarned, userId: userId)
    }

    func cancelSession() async {
        guard var session = activeSession else { return }
        stopTimer()
        session.status = .cancelled
        session.completedAt = Date()
        activeSession = nil
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
    }

    // MARK: - Timer
    private func startTimer() {
        isTimerRunning = true
        timerHandle = _Concurrency.Task {
            while timeRemaining > 0 && !_Concurrency.Task.isCancelled {
                try? await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)
                guard !_Concurrency.Task.isCancelled else { return }
                timeRemaining -= 1
                if timeRemaining == 0 { await handleTimerEnd() }
            }
        }
    }

    private func stopTimer() {
        timerHandle?.cancel()
        timerHandle = nil
        isTimerRunning = false
    }

    private func handleTimerEnd() async {
        if isBreakTime {
            isBreakTime = false
            await completeSession()
        } else {
            isBreakTime = true
            if let session = activeSession {
                timeRemaining = session.breakDurationMinutes * 60
                startTimer()
            }
        }
    }

    private func calculatePoints(for session: FocusSession) -> Int {
        max(0, (session.focusDurationMinutes * 2) - (session.distractionCount * 5))
    }
}
