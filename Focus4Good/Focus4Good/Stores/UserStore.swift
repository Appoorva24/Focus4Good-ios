import Foundation
import Supabase

@MainActor
@Observable
class UserStore {
    
    // MARK: - State
    var currentUser: User?
    var userSettings: UserSettings?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    /// True once restoreSession() has finished (success or failure).
    /// The splash screen waits for this before deciding where to navigate.
    var isSessionReady = false
    /// Set to true when 100 bonus points are awarded on first classroom visit.
    /// VirtualClassroomView triggers this; MainTabView shows the popup.
    var showNewUserBonusPopup = false
    
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
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            isAuthenticated = true
            // Preload user data so stores are ready immediately
            await loadUserData(userId: userId)
        } catch {
            // No saved session — user needs to log in
            isAuthenticated = false
        }
        // Always mark ready so the splash can proceed
        isSessionReady = true
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
            let userId = response.user.id
            // 2. Trigger auto-creates profile. Fetch it.
            await fetchCurrentUser(userId: userId)
            isAuthenticated = true
            // 3. Preload tasks/progress for the new user
            await loadUserData(userId: userId)
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
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            isAuthenticated = true
            // Preload tasks/progress so Schedule is populated immediately
            await loadUserData(userId: userId)
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
        // Clear ALL cached store data
        TaskStore.shared.tasks = []
        TaskStore.shared.categories = []
        ProgressStore.shared.clearData()
        CommunityStore.shared.clearData()
        CalmCentreStore.shared.clearData()
        VolunteerStore.shared.clearData()
        ClassroomStore.shared.clearData()
        // Cancel pending notifications
        NotificationManager.shared.cancelAllNotifications()
    }

    // MARK: - Grant Focus Points (called from VirtualClassroomView on first visit)
    /// Adds `amount` focus points to the current user in Supabase and returns true on success.
    @discardableResult
    func grantBonusPoints(_ amount: Int) async -> Bool {
        guard var user = currentUser else { return false }
        let newPoints = user.focusPoints + amount
        do {
            try await client
                .from("profiles")
                .update(["focus_points": newPoints])
                .eq("id", value: user.id.uuidString)
                .execute()
            user.focusPoints = newPoints
            currentUser = user
            print("🎁 Granted \(amount) bonus focus points")
            return true
        } catch {
            print("❌ Failed to grant bonus points: \(error)")
            return false
        }
    }

    // MARK: - Bulk data load (called after every auth)
    private func loadUserData(userId: UUID) async {
        async let tasks: ()       = TaskStore.shared.fetchTasks(userId: userId)
        async let progress: ()    = ProgressStore.shared.fetchProgress(userId: userId)
        async let communities: () = CommunityStore.shared.fetchCommunities()
        async let categories: ()  = CommunityStore.shared.fetchCommunityCategories()
        async let ngos: ()        = VolunteerStore.shared.fetchNGOs()
        async let events: ()      = VolunteerStore.shared.fetchVolunteerEvents()
        async let regs: ()        = VolunteerStore.shared.fetchRegistrations(userId: userId)
        async let breathing: ()   = CalmCentreStore.shared.fetchBreathingSessions(userId: userId)
        async let jpmr: ()        = CalmCentreStore.shared.fetchJpmrSessions(userId: userId)
        async let meditation: ()  = CalmCentreStore.shared.fetchGuidedMeditationSessions(userId: userId)
        async let asmr: ()        = CalmCentreStore.shared.fetchAsmrSounds()
        async let folders: ()     = CalmCentreStore.shared.fetchBrainDumpFolders(userId: userId)
        async let entries: ()     = CalmCentreStore.shared.fetchBrainDumpEntries(userId: userId)
        async let members: ()     = CommunityStore.shared.fetchAllMembers()
        async let saved: ()       = CommunityStore.shared.fetchSavedPosts(userId: userId)
        _ = await (tasks, progress, communities, categories, ngos, events, regs, breathing, jpmr, meditation, asmr, folders, entries, members, saved)
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
    
    func updateProfile(fullName: String, email: String? = nil, profileImageUrl: String?) async {
        guard let userId = currentUser?.id else { return }
        do {
            var updates: [String: String] = [
                "full_name": fullName,
                "profile_image_url": profileImageUrl ?? ""
            ]
            if let email {
                updates["email"] = email
            }
            
            try await client
                .from("profiles")
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Update local state
            currentUser?.fullName = fullName
            currentUser?.profileImageUrl = profileImageUrl
            if let email {
                currentUser?.email = email
            }
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

