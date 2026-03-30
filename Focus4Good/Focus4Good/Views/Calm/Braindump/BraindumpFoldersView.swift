//
//  BraindumpFoldersView.swift
//  Focus4Good
//
//  Created by Shreya on 20/03/26.
//

import SwiftUI

struct BraindumpFoldersView: View {

    private var store: CalmCentreStore { CalmCentreStore.shared }
    @State private var isEditing = false

    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""

    // Placeholder user ID — swap for real auth later
    private let userId = UUID()

    var body: some View {
        List {
            // Folders section
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
                                .foregroundStyle(Color("CalmOrange"))
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
        .tint(Color("CalmOrange"))
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newFolderName = ""
                    showNewFolderAlert = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(Color("CalmOrange"))
                }
            }

            if !store.brainDumpFolders.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .foregroundStyle(Color("CalmOrange"))
                    }
                }
            }
        }
        .alert("New Folder", isPresented: $showNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                guard !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                store.addBrainDumpFolder(name: newFolderName, userId: userId)
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

    // MARK: - Delete

    private func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            let folder = store.brainDumpFolders[index]
            store.deleteBrainDumpFolder(folder)
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpFoldersView()
    }
}
