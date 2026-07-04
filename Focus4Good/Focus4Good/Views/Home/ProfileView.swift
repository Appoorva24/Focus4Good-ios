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
    @State private var selectedPhotoData: Data? = nil

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
                                if let selectedPhotoData = selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
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
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemBackground))
                                            .frame(width: 28, height: 28)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(AppTheme.orange)
                                    }
                                }
                                .buttonStyle(.plain)
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

                    // Profile Section
                    Section {
                        settingsRow(icon: "person.text.rectangle.fill", label: "Edit Profile", color: AppTheme.orange) {
                            showEditProfile = true
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
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task { @MainActor in
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        self.selectedPhotoData = data
                        // TODO: Once Supabase storage is configured, upload image data here.
                    } else {
                        print("Warning: Loaded data is nil.")
                    }
                } catch {
                    print("Error loading photo: \(error.localizedDescription)")
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
