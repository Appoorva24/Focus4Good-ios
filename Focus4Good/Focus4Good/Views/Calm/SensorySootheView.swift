import SwiftUI

// MARK: - SensorySootheView
/// This view displays a list of ASMR sounds fetched from Supabase.
struct SensorySootheView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore

    // Tracks which sound is currently selected to show in the player sheet
    @State private var selectedSound: AsmrSound?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Search for 'Nature & Calm' to be the hero, otherwise use the first sound
                if let hero = store.asmrSounds.first(where: { $0.name == "Nature & Calm" }) ?? store.asmrSounds.first {
                    heroBanner(for: hero)
                }
                // Show the vertical list of all sounds
                soundList
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ASMR Sounds")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { 
            // When the screen opens, fetch the sounds and the user's favorites from Supabase
            Task {
                await store.fetchAsmrSounds()
                if let userId = userStore.currentUser?.id {
                    await store.fetchFavouriteAsmrSounds(userId: userId)
                }
            }
        }
        // Opens the ASMR player as a slide-up sheet when a sound is selected
        .sheet(item: $selectedSound) { sound in
            ASMRPlayerView(
                sound: sound,
                isFavourite: store.favouriteAsmrSoundIds.contains(sound.id),
                onToggleFavourite: {
                    // Update the favorite status in Supabase when the heart icon is tapped
                    if let userId = userStore.currentUser?.id {
                        Task { await store.toggleAsmrFavourite(soundId: sound.id, userId: userId) }
                    }
                }
            )
            .environment(store)
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    /// Creates a large, beautiful banner for the featured sound
    private func heroBanner(for sound: AsmrSound) -> some View {
        Button {
            selectedSound = sound
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Fetch the image from the URL provided by the backend
                AsyncImage(url: URL(string: sound.imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    // Fallback to local asset if URL fails
                    Image(sound.imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color.gray.opacity(0.2))
                }
                .frame(height: 180)
                .clipped()

                // Gradient overlay to make the white text readable on bright images
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(sound.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Featured Selection")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// The list of all sound rows
    private var soundList: some View {
        VStack(spacing: 12) {
            ForEach(store.asmrSounds) { sound in
                soundRow(sound)
            }
            
            // Show a simple message if no sounds were found in the database
            if store.asmrSounds.isEmpty && !store.isLoading {
                ContentUnavailableView("No Sounds Found", systemImage: "speaker.slash", description: Text("Check back later for new ASMR recordings."))
                    .padding(.top, 40)
            }
        }
    }

    /// A single row for an ASMR sound with its thumbnail and title
    private func soundRow(_ sound: AsmrSound) -> some View {
        Button {
            selectedSound = sound
        } label: {
            HStack(spacing: 14) {
                // Sound Thumbnail from Supabase URL
                AsyncImage(url: URL(string: sound.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    // Fallback to local image if URL is missing
                    Image(sound.imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color(.systemGray6))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(sound.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(sound.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Show a small heart if this sound is a user favorite
                if store.favouriteAsmrSoundIds.contains(sound.id) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SensorySootheView()
            .environment(CalmCentreStore.shared)
            .environment(UserStore.shared)
    }
}
