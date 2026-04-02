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
            .environment(calmCentreStore)
            .environment(communityStore)
            .onAppear {
                Task {
                    _ = await NotificationManager.shared.requestPermission()
                }
            }
        }
    }
}

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
