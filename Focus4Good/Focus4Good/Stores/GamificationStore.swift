import Foundation
import Combine

@MainActor
final class GamificationStore: ObservableObject {

    // MARK: - State
    @Published var levels: [Level] = []
    @Published var milestones: [Milestone] = []
    @Published var userMilestones: [UserMilestone] = []
    @Published var dailyTip: DailyTip?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed
    var currentLevel: Level? {
        guard let user = UserStore.shared.currentUser else { return nil }
        return levels
            .filter { $0.pointsRequired <= user.focusPoints }
            .max(by: { $0.pointsRequired < $1.pointsRequired })
    }

    var nextLevel: Level? {
        guard let user = UserStore.shared.currentUser else { return nil }
        return levels
            .filter { $0.pointsRequired > user.focusPoints }
            .min(by: { $0.pointsRequired < $1.pointsRequired })
    }

    var progressToNextLevel: Double {
        guard let user = UserStore.shared.currentUser,
              let current = currentLevel,
              let next = nextLevel else { return 0 }
        let range = next.pointsRequired - current.pointsRequired
        let progress = user.focusPoints - current.pointsRequired
        return Double(progress) / Double(range)
    }

    var nextMilestone: Milestone? {
        guard let user = UserStore.shared.currentUser else { return nil }
        return milestones
            .filter { milestone in !userMilestones.contains { $0.milestoneId == milestone.id && $0.achievedAt != nil } }
            .filter { $0.pointsRequired > user.focusPoints }
            .min(by: { $0.pointsRequired < $1.pointsRequired })
    }

    var achievedMilestones: [UserMilestone] { userMilestones.filter { $0.achievedAt != nil } }

    static let shared = GamificationStore()
    private init() {}

    // MARK: - Levels
    func fetchLevels() async {
        isLoading = true
        do { isLoading = false }
    }

    // MARK: - Milestones
    func fetchMilestones() async {
        isLoading = true
        do { isLoading = false }
    }

    func fetchUserMilestones(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func updateMilestoneProgress(milestoneId: UUID, progress: Int) async {
        guard let index = userMilestones.firstIndex(where: { $0.milestoneId == milestoneId }) else { return }
        userMilestones[index].progress = progress
        if let target = milestones.first(where: { $0.id == milestoneId }),
           progress >= target.pointsRequired {
            userMilestones[index].achievedAt = Date()
        }
    }

    // MARK: - Daily Tip
    func fetchDailyTip() async {
        isLoading = true
        do { isLoading = false }
    }
}
