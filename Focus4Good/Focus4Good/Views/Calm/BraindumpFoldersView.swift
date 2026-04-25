import SwiftUI

struct BraindumpFoldersView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore

    @State private var isEditing = false
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""

    private var userId: UUID? {
        userStore.currentUser?.id
    }

    var body: some View {
        List {
            Section {
                ForEach(store.brainDumpFolders) { folder in
                    NavigationLink {
                        BraindumpEntriesView(folder: folder)
                    } label: {
                        Label {
                            HStack {
                                Text(folder.name)
                                Spacer()
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newFolderName = ""
                    showNewFolderAlert = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(Color.accentColor)
                }
            }

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
        .alert("New Folder", isPresented: $showNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                guard !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                guard let uid = userId else { return }
                Task { await store.addBrainDumpFolder(name: newFolderName, userId: uid) }
            }
        } message: {
            Text("Enter a name for the new folder.")
        }
        .tint(.primary)
        .overlay {
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
