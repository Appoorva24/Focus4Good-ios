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

                case .onboarding:
                    OnboardingView(onComplete: {
                        appState = .auth
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
                if !isAuth && appState == .app {
                    appState = .auth
                }
            }
            .environment(userStore)
            .environment(taskStore)
            .environment(volunteerStore)
            .environment(progressStore)
            .environment(classroomStore)
            .environment(calmCentreStore)
            .environment(communityStore)
            .onAppear {
                // Request notification permission on first launch
                Task { _ = await NotificationManager.shared.requestPermission() }
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
        } else if userStore.isAuthenticated {
            appState = .app
        } else {
            appState = .auth
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

            // First-visit 100 bonus points popup (triggered by VirtualClassroomView)
            if userStore.showNewUserBonusPopup {
                NewUserBonusPopup {
                    userStore.showNewUserBonusPopup = false
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: userStore.showNewUserBonusPopup)
    }
}

// MARK: - New User Bonus Popup

/// Shown once after sign-up when 100 Focus Points are awarded.
/// Visual style matches PomodoroSessionPopup for consistency.
struct NewUserBonusPopup: View {
    let onContinue: () -> Void

    @State private var starScale: CGFloat = 0.3
    @State private var starOpacity: Double = 0
    @State private var textVisible = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {} // block pass-through

            VStack(spacing: 0) {
                Spacer()

                // Star burst icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFF3E8"), Color(hex: "FFD9B3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: AppTheme.orange.opacity(0.35), radius: 20)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.orange)
                }
                .scaleEffect(starScale)
                .opacity(starOpacity)
                .padding(.bottom, 24)

                if textVisible {
                    VStack(spacing: 12) {
                        Text("Welcome to Focus4Good! 🎉")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("You've received a welcome bonus to get started on your virtual classroom journey!")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)

                        // Points badge
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.title3)
                                .foregroundStyle(AppTheme.orange)
                            Text("+ 100 Focus Points")
                                .font(.title.bold())
                                .foregroundStyle(AppTheme.orange)
                        }
                        .padding(.top, 8)

                        Text("Use them in the Item Shop to unlock classroom items!")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 8)
                }

                Spacer()

                if textVisible {
                    Button(action: onContinue) {
                        HStack(spacing: 8) {
                            Text("Let's Decorate!")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [AppTheme.orange, Color(hex: "F4845F")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                        .shadow(color: AppTheme.orange.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
            .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        }
        .onAppear {
            // Animate icon in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                starScale = 1.0
                starOpacity = 1.0
            }
            // Then reveal text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    textVisible = true
                }
            }
        }
    }
}
