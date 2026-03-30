//
//  BraindumpEntriesView.swift
//  Focus4Good
//
//  Created by Shreya on 20/03/26.
//

import SwiftUI

@available(iOS 17.0, *)
struct BraindumpEntriesView: View {

    let folder: BrainDumpFolder

    private var store: CalmCentreStore { CalmCentreStore.shared }
    @State private var selectedEntry: BrainDumpEntry?

    private var entries: [BrainDumpEntry] {
        store.brainDumpEntries(in: folder)
    }

    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.content)
                                    .lineLimit(2)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Text(entry.createdAt, format: .dateTime.day().month(.wide).year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(Color("CalmOrange"))
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
            ToolbarItem(placement: .topBarTrailing) {
                // Compose new entry
                NavigationLink {
                    BraindumpEditorView(folder: folder)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color("CalmOrange"))
                }
            }

            if !entries.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            entryDetailSheet(entry)
        }
        .overlay {
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

    // MARK: - Detail Sheet

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
                    Button("Done") {
                        selectedEntry = nil
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Delete

    private func deleteEntry(at offsets: IndexSet) {
        let entriesToDelete = offsets.map { entries[$0] }
        for entry in entriesToDelete {
            store.deleteBrainDumpEntry(entry)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        BraindumpEntriesView(
            folder: BrainDumpFolder(userId: UUID(), name: "Random Thoughts", entryCount: 2)
        )
    }
}
