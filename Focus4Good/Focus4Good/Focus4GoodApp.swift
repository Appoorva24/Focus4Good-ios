//
//  Focus4GoodApp.swift
//  Focus4Good
//
//  Created by Appoorva on 20/03/26.
//

import SwiftUI

@main
struct Focus4GoodApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @StateObject private var userStore = UserStore.shared
    @StateObject private var taskStore = TaskStore.shared
    @StateObject private var focusStore = FocusStore.shared
    @StateObject private var volunteerStore = VolunteerStore.shared
    @StateObject private var progressStore = ProgressStore.shared
    @StateObject private var gamificationStore = GamificationStore.shared
    @StateObject private var calmCentreStore = CalmCentreStore.shared

    var body: some Scene {
        WindowGroup {
            if !hasSeenOnboarding {
                OnboardingView()
                    .environmentObject(userStore)
            } else {
                MainTabView()
                    .environmentObject(userStore)
                    .environmentObject(taskStore)
                    .environmentObject(focusStore)
                    .environmentObject(volunteerStore)
                    .environmentObject(progressStore)
                    .environmentObject(gamificationStore)
                    .environmentObject(calmCentreStore)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var focusStore: FocusStore
    @EnvironmentObject private var volunteerStore: VolunteerStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var gamificationStore: GamificationStore
    @EnvironmentObject private var calmCentreStore: CalmCentreStore

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(userStore)
                .environmentObject(taskStore)
                .environmentObject(volunteerStore)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            Text("Progress")
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            Text("Meditate")
                .tabItem {
                    Label("Meditate", systemImage: "figure.mind.and.body")
                }

            Text("Community")
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
        }
        .tint(AppTheme.orange)
    }
}
