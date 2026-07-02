import SwiftUI

struct ProfileView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false
    @State private var showNotificationsAlert = false
    @State private var showTimezoneAlert = false

    private var userName: String { userStore.currentUser?.fullName ?? "Loading…" }
    private var userEmail: String { userStore.currentUser?.email ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                
                List {
                // User Card
                Section {
                    HStack(spacing: 14) {
                        // Gradient ring avatar
                        ZStack {
                            Circle()
                                .fill(AppTheme.buttonGradient)
                                .frame(width: 58, height: 58)
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 52, height: 52)
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(userName).font(.headline).foregroundStyle(AppTheme.warmTextPrimary)
                            Text(userEmail).font(.caption).foregroundStyle(AppTheme.warmTextSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(AppTheme.cardBg)

                // Profile Section
                Section {
                    settingsRow(icon: "person", label: "Edit Profile", color: AppTheme.orange) {
                        showEditProfile = true
                    }
                } header: { Text("Profile").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)

                // App Settings Section
                Section {
                    settingsRow(icon: "bell", label: "Notifications", color: AppTheme.rose) {
                        showNotificationsAlert = true
                    }
                    settingsRow(icon: "globe", label: "Timezone", color: AppTheme.sky) {
                        showTimezoneAlert = true
                    }
                    settingsRow(icon: "lock.shield", label: "Email 2FA", color: AppTheme.sage) {
                        if userStore.hasMfaEnabled {
                            showUnenrollAlert = true
                        } else {
                            showEnrollAlert = true
                        }
                    }
                } header: { Text("App Settings").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .listRowBackground(AppTheme.cardBg)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle().fill(.white)
                                .frame(width: 28, height: 28)
                                .shadow(color: .black.opacity(0.05), radius: 2)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.warmTextPrimary)
                        }
                    }
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
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }

    private func settingsRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color))

                Text(label).font(.subheadline).foregroundStyle(AppTheme.warmTextPrimary)
                Spacer()
                
                if label == "Email 2FA" {
                    Text(userStore.hasMfaEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundStyle(userStore.hasMfaEnabled ? AppTheme.sage : AppTheme.warmTextSecondary)
                }
                
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.warmTextSecondary)
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
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.warmTextSecondary)
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
