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
    @State private var calmCentreStore = CalmCentreStore.shared
    @State private var communityStore  = CommunityStore.shared

    // ── Navigation state ────────────────────────────────────────────
    @State private var appState: AppState = .splash
    
    // ── Scene phase (for re-engagement notifications) ───────────────
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState {

                case .splash:
                    SplashView {
                        handleSplashFinished()
                    }

                case .onboarding:
                    OnboardingView(onComplete: {
                        appState = .app
                    })

                case .auth:
                    AuthView(onSuccess: {
                        // Brief re-splash after login so the user sees the logo
                        appState = .splash
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            appState = .app
                        }
                    })

                case .app:
                    MainTabView()
                }
            }
            // Watch for sign-out: when isAuthenticated flips to false while in the
            // app, send the user back to the auth screen immediately.
            .onChange(of: userStore.isAuthenticated) { _, isAuth in
                // Bypassed for now
                // if !isAuth && appState == .app {
                //     appState = .auth
                // }
            }
            .environment(userStore)
            .environment(taskStore)
            .environment(volunteerStore)
            .environment(progressStore)
            .environment(calmCentreStore)
            .environment(communityStore)
            .onAppear {
                // Request notification permission on first launch
                Task { _ = await NotificationManager.shared.requestPermission() }
            }
            .preferredColorScheme(.light) // Force light mode
        }
        // ── Re-engagement notifications: schedule on background, cancel on active ──
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // User left the app — schedule catchy comeback notifications
                Task {
                    let streak = userStore.currentUser?.currentStreak ?? 0
                    let points = userStore.currentUser?.focusPoints ?? 0
                    let level  = userStore.currentUser?.currentLevel ?? 1
                    await NotificationManager.shared.scheduleReengagementNotifications(
                        streak: streak,
                        points: points,
                        level: level
                    )
                }
            case .active:
                // User is back — cancel any pending re-engagement notifications
                NotificationManager.shared.cancelReengagementNotifications()
            default:
                break
            }
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
            appState = .onboarding
        } else {
            appState = .app
        }
    }
}

// MARK: - Main Tab View

enum AppTab: Hashable {
    case home, progress, calm, community
}

struct MainTabView: View {
    @Environment(UserStore.self) private var userStore
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: .home) {
                    HomeView()
                }
                Tab("Calm", systemImage: "figure.mind.and.body", value: .calm) {
                    CalmCentreView()
                }
                Tab("Community", systemImage: "person.3.fill", value: .community) {
                    CommunityHome()
                }
                Tab("Progress", systemImage: "chart.bar.fill", value: .progress) {
                    ProgressTrackerView()
                }
            }
            .tint(AppTheme.orange)

        }
    }
}

