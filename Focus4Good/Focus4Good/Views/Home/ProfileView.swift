import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false
    @State private var showNotificationsAlert = false
    @State private var showTimezoneAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var showBadges = false

    private var userName: String { userStore.currentUser?.fullName ?? "Loading…" }
    private var userEmail: String { userStore.currentUser?.email ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                
                List {
                    // Profile Header
                    Section {
                        VStack(spacing: 16) {
                            // Large Avatar
                            ZStack {
                                if let uiImage = profileImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                        .shadow(color: AppTheme.orange.opacity(0.3), radius: 10, y: 5)
                                } else {
                                    Circle()
                                        .fill(LinearGradient(colors: [AppTheme.orange, AppTheme.orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 90, height: 90)
                                        .shadow(color: AppTheme.orange.opacity(0.3), radius: 10, y: 5)
                                    
                                    if let firstChar = userStore.currentUser?.fullName.first, firstChar.isLetter {
                                        Text(String(firstChar).uppercased())
                                            .font(.system(size: 40, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Button {
                                    showPhotoPicker = true
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemBackground))
                                            .frame(width: 30, height: 30)
                                            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(AppTheme.orange)
                                    }
                                }
                                .offset(x: 4, y: 4)
                            }
                            .padding(.top, 16)
                            
                            VStack(spacing: 4) {
                                Text(userName)
                                    .font(.title2.bold())
                                    .foregroundStyle(AppTheme.warmTextPrimary)
                                Text(userEmail)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.warmTextSecondary)
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())

                    // Impact Dashboard
                    Section {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                impactStat(
                                    icon: "heart.fill",
                                    value: "\(userStore.totalPointsDonated)",
                                    label: "Pts Donated",
                                    color: AppTheme.rose
                                )
                                impactStat(
                                    icon: "gift.fill",
                                    value: "\(userStore.donationHistory.count)",
                                    label: "Donations",
                                    color: AppTheme.orange
                                )
                            }
                            HStack(spacing: 12) {
                                impactStat(
                                    icon: "star.fill",
                                    value: "\(userStore.currentUser?.focusPoints ?? 0)",
                                    label: "Focus Pts",
                                    color: Color(hex: "F59E0B")
                                )
                                impactStat(
                                    icon: "flame.fill",
                                    value: "\(userStore.currentUser?.bestStreak ?? 0)",
                                    label: "Best Streak",
                                    color: AppTheme.sage
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    } header: { Text("Your Impact").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // Profile Section
                    Section {
                        settingsRow(icon: "person.text.rectangle.fill", label: "Edit Profile", color: AppTheme.orange) {
                            showEditProfile = true
                        }
                        settingsRow(icon: "medal.fill", label: "My Badges", color: AppTheme.sage) {
                            showBadges = true
                        }
                    } header: { Text("Profile").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                    .listRowBackground(AppTheme.cardBg)

                    // App Settings Section
                    Section {
                        settingsRow(icon: "bell.badge.fill", label: "Notifications", color: AppTheme.rose) {
                            showNotificationsAlert = true
                        }
                        settingsRow(icon: "globe.americas.fill", label: "Timezone", color: AppTheme.sky) {
                            showTimezoneAlert = true
                        }
                        // TEMP DEBUG BUTTON
                        settingsRow(icon: "ladybug.fill", label: "Add 10k Points (Debug)", color: .gray) {
                            Task {
                                await userStore.updateFocusPoints(by: 10000)
                            }
                        }
                        // TEMP DEBUG BUTTON 2
                        settingsRow(icon: "arrow.counterclockwise", label: "Reset Badges & Impact", color: .red) {
                            userStore.totalPointsDonated = 0
                            userStore.donationHistory = []
                            UserDefaults.standard.set("[]", forKey: "unlockedBadgeIds")
                        }
                    } header: { Text("App Settings").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                    .listRowBackground(AppTheme.cardBg)

                    // Sign Out
                    Section {
                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            Text("Sign Out")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .listRowBackground(AppTheme.cardBg)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.orange)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let item = newItem else { return }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
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
        .sheet(isPresented: $showBadges) {
            BadgesView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func settingsRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(label).font(.body).foregroundStyle(AppTheme.warmTextPrimary)
                Spacer()
                
                if label == "Email 2FA" {
                    Text(userStore.hasMfaEnabled ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .foregroundStyle(userStore.hasMfaEnabled ? AppTheme.sage : AppTheme.warmTextSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.warmTextSecondary.opacity(0.6))
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    private func impactStat(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warmTextPrimary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
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
