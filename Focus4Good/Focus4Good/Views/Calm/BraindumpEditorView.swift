import SwiftUI

/// This is the writing screen where you compose your brain dump notes.
struct BraindumpEditorView: View {
    // The folder where this note will be saved
    let folder: BrainDumpFolder

    @Environment(\.dismiss) private var dismiss
    // Automatically pops up the keyboard when the screen opens
    @FocusState private var isEditorFocused: Bool
    
    // The text currently being typed
    @State private var text = ""
    // Controls the visibility of the "Well done!" popup
    @State private var showWellDonePopup = false

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore

    // Helper to get the current user's ID
    private var userId: UUID? {
        userStore.currentUser?.id
    }

    var body: some View {
        ZStack {
            // Large writing area
            TextEditor(text: $text)
                .focused($isEditorFocused)
                .padding()

            // A beautiful "Well done!" popup that shows up after you save your note
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
                        .foregroundStyle(Color.accentColor)

                    Text("Well done!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Letting your thoughts out takes efforts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text("+ 10 Focus Points")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
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
                // Back button
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                // Save button
                Button { saveEntry() } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear { isEditorFocused = true }
    }

    /// Saves the typed text as a new note in Supabase
    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isEditorFocused = false // Hide keyboard
        
        Task {
            guard let uid = userId else { return }
            // Push the data to the backend
            await store.addBrainDumpEntry(content: trimmed, userId: uid, folderId: folder.id)
        }
        
        // Show the success animation
        showWellDonePopup = true
    }
}

#Preview {
    NavigationStack {
        BraindumpEditorView(folder: BrainDumpFolder(userId: UUID(), name: "Preview", entryCount: 0))
            .environment(CalmCentreStore.shared)
            .environment(UserStore.shared)
    }
}
