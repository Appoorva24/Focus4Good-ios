import SwiftUI

/// This view displays all the brain dump notes saved inside a specific folder.
struct BraindumpEntriesView: View {

    let folder: BrainDumpFolder

    @Environment(CalmCentreStore.self) private var store
    // State to track which entry is selected for viewing in a sheet
    @State private var selectedEntry: BrainDumpEntry?

    // Filters the store's entries to only show ones belonging to this folder
    private var entries: [BrainDumpEntry] {
        store.brainDumpEntries(in: folder)
    }

    var body: some View {
        List {
            Section {
                // Loop through all entries in this folder
                ForEach(entries) { entry in
                    Button { selectedEntry = entry } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                // Show a preview of the note content
                                Text(entry.content)
                                    .lineLimit(2)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                // Show when the note was created
                                Text(entry.createdAt, format: .dateTime.day().month(.wide).year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .tint(.primary)
                }
                .onDelete(perform: deleteEntry)
            } header: {
                if !entries.isEmpty {
                    Text("\(entries.count) \(entries.count == 1 ? "Entry" : "Entries")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(folder.name)
        .toolbar {
            // Button to open the editor and create a NEW entry in this folder
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    BraindumpEditorView(folder: folder)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Standard Edit button for deleting rows
            if !entries.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
        // Shows the full note content in a popup sheet when tapped
        .sheet(item: $selectedEntry) { entry in
            entryDetailSheet(entry)
        }
        .overlay {
            // Show an empty state message if the folder has no notes
            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("No Entries Yet")
                        .font(.headline)
                    Text("Tap the compose icon to start writing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// The popup sheet that displays the full text of a selected note
    private func entryDetailSheet(_ entry: BrainDumpEntry) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(entry.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.content)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { selectedEntry = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    /// Deletes a note from the Supabase backend
    private func deleteEntry(at offsets: IndexSet) {
        for entry in offsets.map({ entries[$0] }) {
            Task { await store.deleteBrainDumpEntry(entry) }
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpEntriesView(
            folder: BrainDumpFolder(userId: UUID(), name: "Random Thoughts", entryCount: 2)
        )
        .environment(CalmCentreStore.shared)
        .environment(UserStore.shared)
    }
}
