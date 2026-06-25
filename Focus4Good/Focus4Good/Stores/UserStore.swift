import Foundation
import Supabase
import AuthenticationServices
import CryptoKit
import Auth

@MainActor
@Observable
class UserStore {
    
    // MARK: - State
    var currentUser: User?
    var userSettings: UserSettings?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var showNewUserBonusPopup = false
    /// Raw nonce for Apple Sign-In verification
    private var currentNonce: String?
    var isSessionReady = false
    var hasMfaEnabled = false
    var isMfaRequired = false
    var currentMfaFactorId: String?

    
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
            
            // Check Custom Email 2FA Level
            let isEmail2FAEnabled = session.user.userMetadata["email_2fa_enabled"]?.boolValue ?? false
            if isEmail2FAEnabled {
                self.isMfaRequired = true
                self.isLoading = false
                
                // Call Edge Function to send OTP
                _ = try await client.functions.invoke(
                    "send-otp",
                    options: .init(body: ["email": email])
                )
                return
            }
            
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
    
    // MARK: - Apple Sign-In
    
    /// Generates a cryptographic nonce for Apple Sign-In.
    /// Returns the SHA256 hash to pass to the ASAuthorizationAppleIDRequest.
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    /// Handles the Apple Sign-In credential after successful authorization.
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        guard let identityTokenData = credential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8),
              let nonce = currentNonce else {
            errorMessage = "Apple Sign-In failed: could not retrieve credentials."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            isAuthenticated = true
            await loadUserData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        currentNonce = nil
    }
    
    // MARK: - Google Sign-In (Supabase OAuth)
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "focus4good://login-callback")
            )
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            isAuthenticated = true
            await loadUserData(userId: userId)
        } catch {
            // Don't show error when user cancels the web auth session
            if let sessionError = error as? ASWebAuthenticationSessionError,
               sessionError.code == .canceledLogin {
                // User cancelled — no error to display
            } else {
                errorMessage = error.localizedDescription
            }
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
        TaskStore.shared.taskCompletions = [:]
        ProgressStore.shared.clearData()
        CommunityStore.shared.clearData()
        CalmCentreStore.shared.clearData()
        VolunteerStore.shared.clearData()
        // Cancel pending notifications
        NotificationManager.shared.cancelAllNotifications()
    }
    
    // MARK: - Password Reset
    func sendPasswordResetEmail(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    func verifyPasswordResetOTP(email: String, code: String) async throws {
        _ = try await client.auth.verifyOTP(email: email, token: code, type: .recovery)
    }
    
    func updateUserPassword(newPassword: String) async throws {
        _ = try await client.auth.update(user: UserAttributes(password: newPassword))
    }
    // MARK: - Email 2FA Methods
    func checkMFAStatus() async {
        do {
            let session = try await client.auth.session
            hasMfaEnabled = session.user.userMetadata["email_2fa_enabled"]?.boolValue ?? false
        } catch {
            hasMfaEnabled = false
        }
    }
    
    func enrollEmailMFA() async throws {
        _ = try await client.auth.update(user: UserAttributes(data: ["email_2fa_enabled": .bool(true)]))
        await checkMFAStatus()
    }
    
    func unenrollEmailMFA() async throws {
        _ = try await client.auth.update(user: UserAttributes(data: ["email_2fa_enabled": .bool(false)]))
        await checkMFAStatus()
    }
    
    func verifyLoginMFA(email: String, code: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // Call Edge Function to verify OTP
            _ = try await client.functions.invoke(
                "verify-otp",
                options: .init(body: ["email": email, "otp": code])
            )
            
            let session = try await client.auth.session
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            
            isAuthenticated = true
            isMfaRequired = false
            await loadUserData(userId: userId)
        } catch {
            errorMessage = "Invalid or expired OTP."
        }
        isLoading = false
    }

    // MARK: - Bulk data load (called after every auth)
    private func loadUserData(userId: UUID) async {
        // Fetch tasks first since completions depend on task IDs
        await TaskStore.shared.fetchTasks(userId: userId)
        await TaskStore.shared.fetchTaskCompletions(userId: userId)
        
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
        _ = await (progress, communities, categories, ngos, events, regs, breathing, jpmr, meditation, asmr, folders, entries)
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
            await checkMFAStatus()
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
    
    // MARK: - Nonce Helpers (Apple Sign-In)
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

