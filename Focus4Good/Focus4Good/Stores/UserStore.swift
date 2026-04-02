import Foundation

@Observable
class UserStore {

    // MARK: - State
    var currentUser: User?
    var userSettings: UserSettings?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    static let shared = UserStore()
    init() {
        // Initialize with dummy user so the app works without a backend
        currentUser = DummyData.currentUser
    }

    // MARK: - Auth
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        isLoading = false
    }

    func signUp(fullName: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        isLoading = false
    }

    func signOut() {
        currentUser = nil
        userSettings = nil
        isAuthenticated = false
    }

    // MARK: - User
    func fetchCurrentUser(userId: UUID) async {
        isLoading = true
        isLoading = false
    }

    func updateProfile(fullName: String, profileImageUrl: String?) async {
        guard var user = currentUser else { return }
        user.fullName = fullName
        user.profileImageUrl = profileImageUrl
        currentUser = user
    }

    func updateFocusPoints(by amount: Int) async {
        guard var user = currentUser else { return }
        user.focusPoints += amount
        currentUser = user
    }

    func updateStreak(newStreak: Int) async {
        guard var user = currentUser else { return }
        user.currentStreak = newStreak
        if newStreak > user.bestStreak { user.bestStreak = newStreak }
        currentUser = user
    }

    func updateLevel(to level: Int) async {
        guard var user = currentUser else { return }
        user.currentLevel = level
        currentUser = user
    }

    // MARK: - Settings
    func fetchSettings() async {
        guard currentUser != nil else { return }
        isLoading = true
        isLoading = false
    }

    func updateSettings(_ settings: UserSettings) async {
        userSettings = settings
    }
}
