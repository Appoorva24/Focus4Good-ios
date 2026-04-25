import SwiftUI
import PhotosUI

struct AddCommunityView: View {
    @Binding var addCommunity: Bool
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
                        Image("personimage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
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
                        Text(coverImage == nil ? "Add Cover Photo" : "Change Photo")
                            .foregroundStyle(AppTheme.orange)
                    }
                }

                // MARK: Form Fields
                VStack(spacing: 0) {
                    HStack {
                        Text("Name")
                            .font(.headline)
                            .foregroundStyle(Color.primary)

                        Spacer()

                        TextField("Community Name", text: $nameOfCommunity)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    Divider()

                    HStack {
                        Text("Category").font(.headline)
                        Spacer()
                        Menu {
                            Button("Hyperactivity") { category = "Hyperactivity" }
                            Button("Focus") { category = "Focus" }
                            Button("Mindfulness") { category = "Mindfulness" }
                            Button("Study Tips") { category = "Study Tips" }
                            Button("Mental Health") { category = "Mental Health" }
                            Button("Volunteering") { category = "Volunteering" }
                            Button("Other") { category = "Other" }
                        } label: {
                            HStack(spacing: 4) {
                                Text(category.isEmpty ? "Select" : category)
                                    .foregroundStyle(category.isEmpty ? .gray : .primary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding()
                    Divider()

                    VStack(alignment: .leading) {
                        TextField("Description", text: $description, axis: .vertical)
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

                VStack(spacing: 0) {
                    HStack {
                        Toggle(isOn: $isPrivate) {
                            Text("Private Community")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
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
                        let userId = userStore.currentUser?.id ?? UUID()
                        await communityStore.createCommunity(
                            name: nameOfCommunity,
                            description: description.isEmpty ? "A community about \(category.isEmpty ? "various topics" : category)." : description,
                            categoryId: nil,
                            isPrivate: isPrivate,
                            userId: userId,
                            coverImageData: coverImageData
                        )
                        addCommunity = false
                    }
                } label: {
                    Text("Create Community")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(nameOfCommunity.isEmpty ? AppTheme.orange.opacity(0.4) : AppTheme.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(nameOfCommunity.isEmpty)
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
            .navigationBarTitle("Add Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        addCommunity = false
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

// MARK: - Camera Picker (minimal bridge for camera hardware)

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: Image?
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
                parent.image = Image(uiImage: uiImage)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddCommunityView(addCommunity: .constant(true))
        .environment(CommunityStore.shared)
        .environment(UserStore.shared)
}
