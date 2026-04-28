import SwiftUI

/// This view displays the list of folders in the Brain Dump section.
/// Users can create, delete, and navigate into folders to see their notes.
struct BraindumpFoldersView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore

    // UI state for managing the folder creation and editing modes
    @State private var isEditing = false
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""

    // Helper to get the current user's ID
    private var userId: UUID? {
        userStore.currentUser?.id
    }

    var body: some View {
        List {
            Section {
                // Display each folder fetched from Supabase
                ForEach(store.brainDumpFolders) { folder in
                    NavigationLink {
                        // Tapping a folder takes you to the list of notes inside it
                        BraindumpEntriesView(folder: folder)
                    } label: {
                        Label {
                            HStack {
                                Text(folder.name)
                                Spacer()
                                // Show the number of notes inside this folder
                                Text("\(store.brainDumpEntries(in: folder).count)")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .onDelete(perform: deleteFolder)
            } header: {
                if !store.brainDumpFolders.isEmpty {
                    Text("My Folders")
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .tint(.accentColor)
        .navigationTitle("Folders")
        .toolbar {
            // Button to create a new folder
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newFolderName = ""
                    showNewFolderAlert = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Edit button to allow deleting folders
            if !store.brainDumpFolders.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { isEditing.toggle() }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        // Popup to enter a name for a new folder
        .alert("New Folder", isPresented: $showNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                guard !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                guard let uid = userId else { return }
                // Save the new folder to Supabase
                Task { await store.addBrainDumpFolder(name: newFolderName, userId: uid) }
            }
        } message: {
            Text("Enter a name for the new folder.")
        }
        .tint(.primary)
        .overlay {
            // Show an empty state if no folders exist
            if store.brainDumpFolders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("No Folders")
                        .font(.headline)
                    Text("Tap the folder icon above to create one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Deletes the selected folder from Supabase
    private func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            let folder = store.brainDumpFolders[index]
            Task { await store.deleteBrainDumpFolder(folder) }
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpFoldersView()
            .environment(CalmCentreStore.shared)
            .environment(UserStore.shared)
    }
}
