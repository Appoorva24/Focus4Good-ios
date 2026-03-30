import SwiftUI

@main
struct Focus4GoodApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // @State because @Observable classes don't use @StateObject
    @State private var userStore = UserStore.shared
    @State private var taskStore = TaskStore.shared
    @State private var volunteerStore = VolunteerStore.shared
    @State private var progressStore = ProgressStore.shared
    @State private var gamificationStore = GamificationStore.shared
    @State private var calmCentreStore = CalmCentreStore.shared
    @State private var communityStore = CommunityStore.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            }
            .environment(userStore)
            .environment(taskStore)
            .environment(volunteerStore)
            .environment(progressStore)
            .environment(gamificationStore)
            .environment(calmCentreStore)
            .environment(communityStore)
            .onAppear {
                // Request notification permissions on app launch
                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        print("✅ App has notification permissions")
                    } else {
                        print("⚠️ User denied notification permissions")
                    }
                }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ProgressTrackerView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            CalmCentreView()
                .tabItem { Label("Calm", systemImage: "figure.mind.and.body") }

            CommunityHome()
                .tabItem { Label("Community", systemImage: "person.3.fill") }
        }
        .tint(AppTheme.orange)
    }
}
