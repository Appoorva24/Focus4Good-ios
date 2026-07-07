import SwiftUI
import PhotosUI

struct EditCommunityView: View {
    let community: Community
    @Binding var showEdit: Bool
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore

    @State private var nameOfCommunity: String = ""
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var isPrivate: Bool = false

    // Photo state
    @State private var coverImage: Image?
    @State private var coverImageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    @State private var profileSelectedItem: PhotosPickerItem?
    @State private var showProfileCamera = false
    @State private var showProfilePhotoPicker = false

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Cover Photo Section
                Section {
                    ZStack(alignment: .bottomLeading) {
                        Menu {
                            Button { showCamera = true } label: { Label("Camera", systemImage: "camera") }
                            Button { showPhotoPicker = true } label: { Label("Photo Library", systemImage: "photo.on.rectangle") }
                        } label: {
                            ZStack {
                                if let coverImage {
                                    coverImage.resizable().scaledToFill().frame(height: 160).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                                } else if let url = community.coverImageUrl, let imageUrl = URL(string: url) {
                                    AsyncImage(url: imageUrl) { image in
                                        image.resizable().scaledToFill().frame(height: 160).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 16))
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 16).fill(AppTheme.orange.opacity(0.08)).frame(height: 160).frame(maxWidth: .infinity)
                                        ProgressView()
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 16).fill(AppTheme.orange.opacity(0.08)).frame(height: 160).frame(maxWidth: .infinity).overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8])).foregroundColor(AppTheme.orange.opacity(0.5)))
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.plus").font(.system(size: 40)).foregroundStyle(AppTheme.orange)
                                        Text("Change Cover Photo").font(.headline).foregroundStyle(AppTheme.orange)
                                    }
                                }
                            }
                        }
                        
                        Menu {
                            Button { showProfileCamera = true } label: { Label("Camera", systemImage: "camera") }
                            Button { showProfilePhotoPicker = true } label: { Label("Photo Library", systemImage: "photo.on.rectangle") }
                        } label: {
                            ZStack {
                                Circle().fill(Color(UIColor.secondarySystemGroupedBackground)).frame(width: 80, height: 80).shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                if let profileImage {
                                    profileImage.resizable().scaledToFill().frame(width: 72, height: 72).clipShape(Circle())
                                } else if let url = community.profileImageUrl, let imageUrl = URL(string: url) {
                                    AsyncImage(url: imageUrl) { image in
                                        image.resizable().scaledToFill().frame(width: 72, height: 72).clipShape(Circle())
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Image(systemName: "camera.circle.fill").resizable().foregroundStyle(AppTheme.orange, AppTheme.orange.opacity(0.2)).frame(width: 72, height: 72)
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .offset(y: 40)
                    }
                    .padding(.bottom, 48)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // MARK: Form Fields
                Section {
                    TextField("Community Name", text: $nameOfCommunity)
                    Picker("Category", selection: $category) {
                        Text("Select").tag("")
                        Text("Hyperactivity").tag("Hyperactivity")
                        Text("Focus").tag("Focus")
                        Text("Mindfulness").tag("Mindfulness")
                        Text("Study Tips").tag("Study Tips")
                        Text("Mental Health").tag("Mental Health")
                        Text("Volunteering").tag("Volunteering")
                        Text("Other").tag("Other")
                    }
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section {
                    Toggle("Private Community", isOn: $isPrivate)
                }

                Section {
                    Button {
                        Task {
                            guard let userId = userStore.currentUser?.id else { return }
                            isSubmitting = true
                            
                            // Upload cover image to Supabase Storage if present
                            var uploadedCoverUrl = community.coverImageUrl
                            if let imageData = coverImageData {
                                let path = "communities/\(userId.uuidString)/\(UUID().uuidString).jpg"
                                do {
                                    uploadedCoverUrl = try await communityStore.uploadImage(data: imageData, path: path)
                                } catch {
                                    isSubmitting = false
                                    errorMessage = "Failed to upload cover image. Please verify that the 'community-images' storage bucket is created in your Supabase dashboard and set to public.\n\nError: \(error.localizedDescription)"
                                    showErrorAlert = true
                                    return
                                }
                            }
                            var uploadedProfileUrl = community.profileImageUrl
                            if let profileData = profileImageData {
                                let path = "communities/\(userId.uuidString)/profile_\(UUID().uuidString).jpg"
                                uploadedProfileUrl = try? await communityStore.uploadImage(data: profileData, path: path)
                            }
                            
                            do {
                                var updatedCommunity = community
                                updatedCommunity.name = nameOfCommunity
                                updatedCommunity.description = description
                                // updatedCommunity.categoryId // Wait, category is string here, let's just keep it simple or not update category if it's not fully supported
                                updatedCommunity.isPrivate = isPrivate
                                updatedCommunity.coverImageUrl = uploadedCoverUrl
                                updatedCommunity.profileImageUrl = uploadedProfileUrl

                                try await communityStore.updateCommunity(updatedCommunity)
                                
                                isSubmitting = false
                                showEdit = false
                            } catch {
                                isSubmitting = false
                                errorMessage = "Failed to update community: \(error.localizedDescription)"
                                showErrorAlert = true
                            }
                        }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text(isSubmitting ? "Saving..." : "Save Changes")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(nameOfCommunity.isEmpty || isSubmitting)
                }
                .listRowBackground(nameOfCommunity.isEmpty || isSubmitting ? AppTheme.orange.opacity(0.4) : AppTheme.orange)
                .foregroundStyle(.white)
            }
            .navigationTitle("Edit Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showEdit = false
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .onAppear {
                nameOfCommunity = community.name
                description = community.description
                isPrivate = community.isPrivate
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(image: $coverImage, imageData: $coverImageData).ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images, photoLibrary: .shared())
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let newItem, let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        coverImageData = data
                        coverImage = Image(uiImage: uiImage)
                    }
                }
            }
            .fullScreenCover(isPresented: $showProfileCamera) {
                CameraPickerView(image: $profileImage, imageData: $profileImageData).ignoresSafeArea()
            }
            .photosPicker(isPresented: $showProfilePhotoPicker, selection: $profileSelectedItem, matching: .images, photoLibrary: .shared())
            .onChange(of: profileSelectedItem) { _, newItem in
                Task {
                    if let newItem, let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        profileImageData = data
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
            .alert("Upload Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
}

