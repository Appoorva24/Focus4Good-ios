//
//  BraindumpEditorView.swift
//  Focus4Good
//
//  Created by Shreya on 20/03/26.
//

import SwiftUI

struct BraindumpEditorView: View {

    let folder: BrainDumpFolder

    @ObservedObject private var store = CalmCentreStore.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEditorFocused: Bool

    @State private var text = ""
    @State private var showWellDonePopup = false

    // Placeholder user ID — swap for real auth later
    private let userId = UUID()

    var body: some View {
        ZStack {
            TextEditor(text: $text)
                .focused($isEditorFocused)
                .padding()

            // MARK: Well Done Popup Overlay
            if showWellDonePopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showWellDonePopup = false
                        dismiss()
                    }

                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color("CalmOrange"))

                    Text("Well done!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Letting your thoughts out takes efforts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text("+ 10 Focus Points")
                        .font(.headline)
                        .foregroundStyle(Color("CalmOrange"))
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showWellDonePopup)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveEntry()
                } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("CalmOrange"))
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            isEditorFocused = true
        }
    }

    // MARK: - Save

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isEditorFocused = false
        Task {
            await store.addBrainDumpEntry(content: trimmed, userId: userId, folderId: folder.id)
        }
        showWellDonePopup = true
    }
}

#Preview {
    NavigationStack {
        BraindumpEditorView(
            folder: BrainDumpFolder(userId: UUID(), name: "Preview", entryCount: 0)
        )
    }
}
