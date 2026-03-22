import Foundation

@Observable
@MainActor
final class GamificationStore {

    // MARK: - State
    var levels: [Level] = []
    var milestones: [Milestone] = []
    var userMilestones: [UserMilestone] = []
    var dailyTip: DailyTip?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
    var currentLevel: Level? {
        guard let points = UserStore.shared.currentUser?.focusPoints else { return nil }
        return levels.filter { $0.pointsRequired <= points }.max(by: { $0.pointsRequired < $1.pointsRequired })
    }

    var nextLevel: Level? {
        guard let points = UserStore.shared.currentUser?.focusPoints else { return nil }
        return levels.filter { $0.pointsRequired > points }.min(by: { $0.pointsRequired < $1.pointsRequired })
    }

    var progressToNextLevel: Double {
        guard let points = UserStore.shared.currentUser?.focusPoints,
              let current = currentLevel, let next = nextLevel else { return 0 }
        let range = next.pointsRequired - current.pointsRequired
        guard range > 0 else { return 1 }
        return Double(points - current.pointsRequired) / Double(range)
    }

    var nextMilestone: Milestone? {
        guard let points = UserStore.shared.currentUser?.focusPoints else { return nil }
        let achieved = Set(userMilestones.compactMap { $0.achievedAt != nil ? $0.milestoneId : nil })
        return milestones.filter { !achieved.contains($0.id) && $0.pointsRequired > points }
            .min(by: { $0.pointsRequired < $1.pointsRequired })
    }

    var achievedMilestones: [UserMilestone] { userMilestones.filter { $0.achievedAt != nil } }

    static let shared = GamificationStore()
    private init() {}

    func fetchLevels() async { isLoading = true; isLoading = false }
    func fetchMilestones() async { isLoading = true; isLoading = false }
    func fetchUserMilestones(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchDailyTip() async { isLoading = true; isLoading = false }

    func updateMilestoneProgress(milestoneId: UUID, progress: Int) async {
        guard let index = userMilestones.firstIndex(where: { $0.milestoneId == milestoneId }) else { return }
        userMilestones[index].progress = progress
        if let target = milestones.first(where: { $0.id == milestoneId }), progress >= target.pointsRequired {
            userMilestones[index].achievedAt = Date()
        }
    }
}
