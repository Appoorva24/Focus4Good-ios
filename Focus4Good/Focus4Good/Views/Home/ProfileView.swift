import SwiftUI

struct ProfileView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false
    @State private var showNotificationsAlert = false
    @State private var showTimezoneAlert = false
    @State private var showEnrollAlert = false
    @State private var showUnenrollAlert = false

    private var userName: String { userStore.currentUser?.fullName ?? "Loading…" }
    private var userEmail: String { userStore.currentUser?.email ?? "" }

    var body: some View {
        NavigationStack {
            List {
                // User Card
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(AppTheme.orange.opacity(0.15)).frame(width: 56, height: 56)
                            Image(systemName: "person.fill").font(.title2).foregroundStyle(AppTheme.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(userName).font(.headline)
                            Text(userEmail).font(.caption).foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Profile Section
                Section {
                    settingsRow(icon: "person", label: "Edit Profile") {
                        showEditProfile = true
                    }
                } header: { Text("Profile").textCase(nil) }

                // App Settings Section
                Section {
                    settingsRow(icon: "bell", label: "Notifications") {
                        showNotificationsAlert = true
                    }
                    settingsRow(icon: "globe", label: "Timezone") {
                        showTimezoneAlert = true
                    }
                    settingsRow(icon: "lock.shield", label: "Email 2FA") {
                        if userStore.hasMfaEnabled {
                            showUnenrollAlert = true
                        } else {
                            showEnrollAlert = true
                        }
                    }
                } header: { Text("App Settings").textCase(nil) }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
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
        .alert("Disable Email 2FA?", isPresented: $showUnenrollAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disable", role: .destructive) {
                Task {
                    try? await userStore.unenrollEmailMFA()
                }
            }
        } message: { Text("Are you sure you want to disable Email Two-Factor Authentication?") }
        .alert("Enable Email 2FA?", isPresented: $showEnrollAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Enable") {
                Task {
                    try? await userStore.enrollEmailMFA()
                }
            }
        } message: { Text("We will send a 6-digit code to your email every time you log in.") }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }

    private func settingsRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 28, height: 28)
                Text(label).font(.subheadline).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                
                if label == "Email 2FA" {
                    Text(userStore.hasMfaEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundStyle(userStore.hasMfaEnabled ? AppTheme.orange : AppTheme.textSecondary)
                }
                
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct EditProfileView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person").foregroundStyle(AppTheme.orange).frame(width: 20)
                        TextField("Full Name", text: $fullName).font(.subheadline)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "envelope").foregroundStyle(AppTheme.orange).frame(width: 20)
                        TextField("Email", text: $email).font(.subheadline)
                            .keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    }
                } header: { Text("Personal Info").textCase(nil) }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            await userStore.updateProfile(fullName: fullName, profileImageUrl: nil)
                        }
                        dismiss()
                    }
                    .font(.headline).foregroundStyle(AppTheme.orange)
                }
            }
            .onAppear {
                fullName = userStore.currentUser?.fullName ?? ""
                email = userStore.currentUser?.email ?? ""
            }
        }
    }
}
