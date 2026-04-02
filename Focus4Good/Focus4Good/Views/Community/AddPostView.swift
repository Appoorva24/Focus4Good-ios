import SwiftUI
import PhotosUI

enum PostHashtag: String, CaseIterable, Identifiable {
    case none = "None"
    case adhd = "ADHD"
    case focusTips = "FocusTips"
    case mindfulness = "Mindfulness"
    case studying = "Studying"
    case sleepHygiene = "SleepHygiene"
    case diagnosis = "Diagnosis"
    case motivation = "Motivation"
    case question = "Question"
    case other = "Other"
    
    var id: String { self.rawValue }
}

struct AddPostView: View {
    @Binding var isPresented: Bool
    var community: Community
    @Environment(CommunityStore.self) private var store
    @Environment(UserStore.self) private var userStore

    @State private var postDescription: String = ""
    @State private var selectedHashtag: PostHashtag = .none

    // Photo state
    @State private var coverImage: Image?
    @State private var coverImageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: Cover Photo Section
                VStack {
                    if let coverImage {
                        coverImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding()
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppTheme.orange.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(AppTheme.orange)
                        }
                        .padding()
                    }

                    Menu {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                        }

                        Button {
                            showPhotoPicker = true
                        } label: {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Text(coverImage == nil ? "Add Photo" : "Change Photo")
                            .foregroundStyle(AppTheme.orange)
                    }
                }

                // MARK: Form Fields
                VStack(spacing: 0) {
                    HStack {
                        Text("Hashtag").font(.headline)
                        Spacer()
                        Picker("Select Hashtag", selection: $selectedHashtag) {
                            ForEach(PostHashtag.allCases) { tag in
                                Text(tag == .none ? "No Hashtag" : "#\(tag.rawValue)").tag(tag)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.gray)
                    }
                    .padding()
                    Divider()

                    VStack(alignment: .leading) {
                        TextField("Description", text: $postDescription, axis: .vertical)
                            .lineLimit(4...8)
                            .padding(.vertical, 4)
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(1.0), lineWidth: 1)
                )
                .padding(.horizontal)

                Button {
                    Task {
                        let currUser = userStore.currentUser
                        let authorId = currUser?.id ?? UUID()
                        let authorName = currUser?.fullName ?? "You"
                        let authorImageUrl = currUser?.profileImageUrl
                        
                        let tag = selectedHashtag == .none ? nil : selectedHashtag.rawValue
                        
                        await store.createPost(
                            content: postDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                            communityId: community.id,
                            authorId: authorId,
                            authorName: authorName,
                            authorImageUrl: authorImageUrl,
                            postImageData: coverImageData,
                            hashtag: tag
                        )
                        isPresented = false
                    }
                } label: {
                    Text("Post")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(postDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.orange.opacity(0.4) : AppTheme.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(postDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
            .navigationBarTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(image: $coverImage, imageData: $coverImageData)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker,
                          selection: $selectedItem,
                          matching: .images,
                          photoLibrary: .shared())
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        coverImageData = data
                        coverImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}
