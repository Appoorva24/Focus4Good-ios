//
//  ContentView.swift
//  Focus4Good
//
//  Created by Appoorva on 20/03/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .progress

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                Text("Home")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Tab("Progress", systemImage: "square.grid.2x2", value: .progress) {
                ProgressTrackerView()
            }

            Tab("Meditate", systemImage: "brain.head.profile", value: .meditate) {
                Text("Meditate")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Tab("Community", systemImage: "person.3", value: .community) {
                Text("Community")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(Color(red: 0.91, green: 0.57, blue: 0.23))
    }
}

enum AppTab: Hashable {
    case home
    case progress
    case meditate
    case community
}

#Preview {
    ContentView()
        .environment(ProgressStore.shared)
}
