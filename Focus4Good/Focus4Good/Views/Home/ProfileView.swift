import SwiftUI

struct ProfileView: View {
    @Environment(UserStore.self) private var userStore
    @State private var showSignOutAlert = false
    @State private var showNotificationsAlert = false
    @State private var showTimezoneAlert = false
    @State private var showPrivacyAlert = false

    private var user: User { userStore.currentUser ?? DummyData.currentUser }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(AppTheme.orange.opacity(0.15)).frame(width: 72, height: 72)
                        Image(systemName: "person.fill").font(.system(size: 32)).foregroundStyle(AppTheme.orange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName).font(.title3.bold())
                        Text(user.email).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                statRow(icon: "flame.fill", label: "Current Streak", value: "\(user.currentStreak) days", color: .orange)
                statRow(icon: "star.fill", label: "Best Streak", value: "\(user.bestStreak) days", color: .yellow)
                statRow(icon: "bolt.fill", label: "Focus Points", value: "\(user.focusPoints)", color: AppTheme.orange)
                statRow(icon: "chart.bar.fill", label: "Level", value: "Level \(user.currentLevel)", color: .purple)
            } header: { Text("Stats").textCase(nil) }

            Section {
                settingsRow(icon: "bell.fill", label: "Notifications", color: .red) { showNotificationsAlert = true }
                settingsRow(icon: "globe", label: "Timezone", color: .blue) { showTimezoneAlert = true }
                settingsRow(icon: "lock.fill", label: "Privacy", color: .gray) { showPrivacyAlert = true }
            } header: { Text("Settings").textCase(nil) }

            Section {
                Button(role: .destructive) { showSignOutAlert = true } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { userStore.signOut() }
        } message: { Text("Are you sure you want to sign out?") }
        .alert("Notifications", isPresented: $showNotificationsAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Notification settings will be available when backend is connected.") }
        .alert("Timezone", isPresented: $showTimezoneAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Current timezone: New Delhi (IST)") }
        .alert("Privacy", isPresented: $showPrivacyAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Privacy settings will be available when backend is connected.") }
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 24)
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func settingsRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 6).fill(color))
                Text(label).font(.subheadline).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
