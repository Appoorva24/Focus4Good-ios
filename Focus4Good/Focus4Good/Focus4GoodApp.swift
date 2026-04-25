import SwiftUI

@main
struct Focus4GoodApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var userStore = UserStore.shared
    @State private var taskStore = TaskStore.shared
    @State private var volunteerStore = VolunteerStore.shared
    @State private var progressStore = ProgressStore.shared
    @State private var calmCentreStore = CalmCentreStore.shared
    @State private var communityStore = CommunityStore.shared
    
    /// Prevents the app from flashing to auth/main before session restore completes
    @State private var isRestoringSession = true

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    // Step 1: First launch → show onboarding
                    OnboardingView()
                        .transition(.move(edge: .trailing))
                } else if isRestoringSession {
                    // Step 2: Wait for session restore before deciding auth vs main
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                } else if !userStore.isAuthenticated {
                    // Step 3: No session → show login/signup
                    AuthView()
                        .transition(.opacity)
                } else {
                    // Step 4: Authenticated → show main app
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
            .animation(.easeInOut(duration: 0.3), value: userStore.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: isRestoringSession)
            .environment(userStore)
            .environment(taskStore)
            .environment(volunteerStore)
            .environment(progressStore)
            .environment(calmCentreStore)
            .environment(communityStore)
            .task {
                // Wait for UserStore session restore to finish
                // UserStore.init() already kicks off restoreSession(),
                // but we wait here for it to settle before removing the loading screen
                // Give the restore a moment to complete
                try? await Task.sleep(for: .milliseconds(500))
                // After the sleep, UserStore.isAuthenticated is set (true or false)
                isRestoringSession = false
                
                _ = await NotificationManager.shared.requestPermission()
            }
            .onChange(of: userStore.isAuthenticated) { _, isAuth in
                if isAuth, let userId = userStore.currentUser?.id {
                    // Fetch all data when user logs in
                    Task {
                        await taskStore.fetchTasks(userId: userId)
                        await taskStore.fetchCategories()
                        await progressStore.fetchProgress(userId: userId)
                        await communityStore.fetchCommunities()
                        await communityStore.fetchCommunityCategories()
                        await communityStore.fetchSavedPosts(userId: userId)
                        await calmCentreStore.fetchBreathingSessions(userId: userId)
                        await calmCentreStore.fetchJpmrSessions(userId: userId)
                        await calmCentreStore.fetchGuidedMeditationSessions(userId: userId)
                        await calmCentreStore.fetchAsmrSounds()
                        await calmCentreStore.fetchFavouriteAsmrSounds(userId: userId)
                        await calmCentreStore.fetchBrainDumpFolders(userId: userId)
                        await calmCentreStore.fetchBrainDumpEntries(userId: userId)
                        await volunteerStore.fetchNGOs()
                        await volunteerStore.fetchVolunteerEvents()
                        await volunteerStore.fetchRegistrations(userId: userId)
                    }
                }
            }
        }
    }
}

// MARK: - Tabs

enum AppTab: Hashable {
    case home, progress, calm, community
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
            }

            Tab("Progress", systemImage: "chart.bar.fill", value: .progress) {
                ProgressTrackerView()
            }

            Tab("Calm", systemImage: "figure.mind.and.body", value: .calm) {
                CalmCentreView()
            }

            Tab("Community", systemImage: "person.3.fill", value: .community) {
                CommunityHome()
            }
        }
        .tint(AppTheme.orange)
    }
}

