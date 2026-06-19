import SwiftUI
import PhotosUI

// MARK: - Local Profile Image Helper

/// Saves and loads profile images to/from the app's documents directory
enum ProfileImageStore {
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
    }

    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL)
    }

    static func load() -> UIImage? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Email Validation

extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Profile View (Apple Health Style)

struct ProfileView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    @State private var profileUIImage: UIImage?

    private var userName: String { userStore.currentUser?.fullName ?? "User" }
    private var userEmail: String { userStore.currentUser?.email ?? "" }
    private var userInitials: String {
        let parts = userName.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "U" : initials.uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Profile Photo Section ─────────────────────────
                    profilePhotoSection
                        .padding(.top, 24)
                        .padding(.bottom, 28)

                    // ── Account Section ────────────────────────────────
                    sectionHeader("Account")
                    groupedCard {
                        profileRow(icon: "person.fill", label: "Name", value: userName)
                        rowDivider
                        profileRow(icon: "envelope.fill", label: "Email", value: userEmail)
                        rowDivider
                        profileRow(icon: "pencil", label: "Edit Profile") {
                            showEditProfile = true
                        }
                    }

                    // ── App Settings Section ──────────────────────────
                    sectionHeader("App Settings")
                    groupedCard {
                        navigationRow(icon: "bell.fill", label: "Notifications") {
                            openAppSettings()
                        }
                    }

                    // ── Privacy Section ───────────────────────────────
                    sectionHeader("Privacy")
                    groupedCard {
                        NavigationLink {
                            DataPrivacyView()
                        } label: {
                            navigationRowContent(icon: "lock.shield.fill", label: "Data & Privacy")
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        NavigationLink {
                            PermissionsView()
                        } label: {
                            navigationRowContent(icon: "hand.raised.fill", label: "Permissions")
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Privacy Note ──────────────────────────────────
                    Text("Your data is stored securely and can only be\nshared with your permission.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 32)

                    // ── Sign Out ──────────────────────────────────────
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .font(.body)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.tertiarySystemFill)))
                    }
                }
            }
            .onAppear {
                // Load saved profile image
                profileUIImage = ProfileImageStore.load()
            }
        }
        .alert("Sign Out?", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                userStore.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showEditProfile, onDismiss: {
            // Reload image after edit sheet closes
            profileUIImage = ProfileImageStore.load()
        }) {
            EditProfileSheet()
        }
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            if let profileUIImage {
                Image(uiImage: profileUIImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.orange.opacity(0.2), radius: 12, y: 4)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.orange.opacity(0.3), AppTheme.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .overlay(
                        Text(userInitials)
                            .font(.system(size: 38, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.orange)
                    )
                    .shadow(color: AppTheme.orange.opacity(0.2), radius: 12, y: 4)
            }

            VStack(spacing: 4) {
                Text(userName)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(userEmail)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func groupedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 16)
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 52)
    }

    private func profileRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppTheme.orange)
                .frame(width: 24)
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func profileRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 24)
                Text(label)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    private func navigationRow(icon: String, label: String, detail: String? = nil, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            navigationRowContent(icon: icon, label: label, detail: detail)
        }
        .buttonStyle(.plain)
    }

    private func navigationRowContent(icon: String, label: String, detail: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppTheme.orange)
                .frame(width: 24)
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var pickedUIImage: UIImage?
    @State private var isSaving = false
    @FocusState private var focusedField: EditField?

    enum EditField: Hashable {
        case name, email
    }

    // MARK: - Validation

    private var isNameValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isEmailValid: Bool {
        email.trimmingCharacters(in: .whitespaces).isValidEmail
    }

    private var canSave: Bool {
        isNameValid && isEmailValid && !isSaving
    }

    private var emailValidationMessage: String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Email is required" }
        if !trimmed.isValidEmail { return "Enter a valid email address" }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ── Photo Picker ─────────────────────────────────
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.orange.opacity(0.3), AppTheme.orange.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(AppTheme.orange)
                                    )
                            }

                            ZStack {
                                Circle().fill(Color(.systemBackground)).frame(width: 32, height: 32)
                                Circle().fill(AppTheme.orange).frame(width: 28, height: 28)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 2, y: 2)
                        }
                    }
                    .padding(.top, 16)

                    Text("Tap to change photo")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.top, -16)

                    // ── Fields ────────────────────────────────────────
                    VStack(spacing: 0) {
                        // Name field
                        editField(
                            icon: "person.fill",
                            placeholder: "Full Name",
                            text: $fullName,
                            field: .name
                        )

                        Divider().padding(.leading, 52)

                        // Email field
                        editField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            field: .email,
                            keyboard: .emailAddress,
                            autocapitalize: false
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 16)

                    // ── Email Validation Feedback ─────────────────────
                    if let message = emailValidationMessage, !email.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, -16)
                    }

                    // ── Note ──────────────────────────────────────────
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Email changes will take effect on next sign-in.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(AppTheme.orange)
                        } else {
                            Text("Save")
                                .font(.headline)
                                .foregroundStyle(canSave ? AppTheme.orange : AppTheme.orange.opacity(0.4))
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                fullName = userStore.currentUser?.fullName ?? ""
                email = userStore.currentUser?.email ?? ""
                // Load existing saved photo
                if let savedImage = ProfileImageStore.load() {
                    profileImage = Image(uiImage: savedImage)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pickedUIImage = uiImage
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }

    private func editField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: EditField,
        keyboard: UIKeyboardType = .default,
        autocapitalize: Bool = true
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppTheme.orange)
                .frame(width: 24)
            TextField(placeholder, text: text)
                .font(.body)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalize ? .words : .never)
                .autocorrectionDisabled(!autocapitalize)
                .focused($focusedField, equals: field)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func saveProfile() {
        isSaving = true
        let trimmedName = fullName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        // Save photo locally if a new one was picked
        if let pickedUIImage {
            ProfileImageStore.save(pickedUIImage)
        }

        Task {
            await userStore.updateProfile(
                fullName: trimmedName,
                email: trimmedEmail,
                profileImageUrl: userStore.currentUser?.profileImageUrl
            )
            isSaving = false
            dismiss()
        }
    }
}
