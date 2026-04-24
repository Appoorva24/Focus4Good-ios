import Foundation
import Supabase

@Observable
class UserStore {
    
    // MARK: - State
    var currentUser: User?
    var userSettings: UserSettings?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    
    static let shared = UserStore()
    
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    init() {
        // Check if user is already logged in from a previous session
        Task { await restoreSession() }
    }
    
    // MARK: - Session Restore
    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            await fetchCurrentUser(userId: session.user.id)
            isAuthenticated = true
        } catch {
            // No saved session — user needs to log in
            isAuthenticated = false
        }
    }
    
    // MARK: - Auth
    func signUp(fullName: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // 1. Create the auth account
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]  // passed to trigger
            )
            // 2. Trigger auto-creates profile. Fetch it.
            await fetchCurrentUser(userId: response.user.id)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            await fetchCurrentUser(userId: session.user.id)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() {
        Task {
            try? await client.auth.signOut()
        }
        currentUser = nil
        userSettings = nil
        isAuthenticated = false
    }
    
    // MARK: - Profile CRUD
    func fetchCurrentUser(userId: UUID) async {
        isLoading = true
        do {
            let user: User = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            currentUser = user
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func updateProfile(fullName: String, profileImageUrl: String?) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await client
                .from("profiles")
                .update([
                    "full_name": fullName,
                    "profile_image_url": profileImageUrl ?? ""
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Update local state
            currentUser?.fullName = fullName
            currentUser?.profileImageUrl = profileImageUrl
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateFocusPoints(by amount: Int) async {
        guard var user = currentUser else { return }
        let newPoints = user.focusPoints + amount
        do {
            try await client
                .from("profiles")
                .update(["focus_points": newPoints])
                .eq("id", value: user.id.uuidString)
                .execute()
            user.focusPoints = newPoints
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateStreak(newStreak: Int) async {
        guard var user = currentUser else { return }
        do {
            var updates: [String: Int] = ["current_streak": newStreak]
            if newStreak > user.bestStreak {
                updates["best_streak"] = newStreak
            }
            try await client
                .from("profiles")
                .update(updates)
                .eq("id", value: user.id.uuidString)
                .execute()
            user.currentStreak = newStreak
            if newStreak > user.bestStreak { user.bestStreak = newStreak }
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateLevel(to level: Int) async {
        guard var user = currentUser else { return }
        do {
            try await client
                .from("profiles")
                .update(["current_level": level])
                .eq("id", value: user.id.uuidString)
                .execute()
            user.currentLevel = level
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Settings
    func fetchSettings() async {
        guard let userId = currentUser?.id else { return }
        isLoading = true
        do {
            let settings: [UserSettings] = try await client
                .from("user_settings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            userSettings = settings.first
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func updateSettings(_ settings: UserSettings) async {
        do {
            try await client
                .from("user_settings")
                .upsert(settings)
                .execute()
            userSettings = settings
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

