import SwiftUI

// MARK: - App State Machine

enum AppState {
    /// Logo splash screen (initial + post-auth)
    case splash
    /// Onboarding slides (first launch only)
    case onboarding
    /// Sign-in / Sign-up
    case auth
    /// Main tab bar
    case app
}

@main
struct Focus4GoodApp: App {

    // ── Persistent flags ────────────────────────────────────────────
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // ── Stores ──────────────────────────────────────────────────────
    @State private var userStore    = UserStore.shared
    @State private var taskStore    = TaskStore.shared
    @State private var volunteerStore = VolunteerStore.shared
    @State private var progressStore  = ProgressStore.shared
    @State private var classroomStore = ClassroomStore.shared
    @State private var calmCentreStore = CalmCentreStore.shared
    @State private var communityStore  = CommunityStore.shared

    // ── Navigation state ────────────────────────────────────────────
    @State private var appState: AppState = .splash

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState {

                case .splash:
                    SplashView {
                        handleSplashFinished()
                    }
                    .transition(.opacity)

                case .onboarding:
                    OnboardingView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState = .auth
                        }
                    })
                    .transition(.opacity)

                case .auth:
                    AuthView(onSuccess: {
                        // Brief re-splash after login so the user sees the logo
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState = .splash
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                appState = .app
                            }
                        }
                    })
                    .transition(.opacity)

                case .app:
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: appState)
            // Watch for sign-out: when isAuthenticated flips to false while in the
            // app, send the user back to the auth screen immediately.
            .onChange(of: userStore.isAuthenticated) { _, isAuth in
                if !isAuth && appState == .app {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState = .auth
                    }
                }
            }
            .environment(userStore)
            .environment(taskStore)
            .environment(volunteerStore)
            .environment(progressStore)
            .environment(classroomStore)
            .environment(calmCentreStore)
            .environment(communityStore)
        }
    }

    // MARK: - Helpers

    private func handleSplashFinished() {
        // Wait for session check to complete before deciding
        guard userStore.isSessionReady else {
            // Check again in 0.1s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                handleSplashFinished()
            }
            return
        }
        
        if !hasSeenOnboarding {
            withAnimation(.easeInOut(duration: 0.4)) {
                appState = .onboarding
            }
        } else if userStore.isAuthenticated {
            withAnimation(.easeInOut(duration: 0.4)) {
                appState = .app
            }
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                appState = .auth
            }
        }
    }
}

// MARK: - Main Tab View

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
