import SwiftUI

struct ASMRPlaylistDetailView: View {
    
    let playlist: ASMRPlaylist
    @Environment(CalmCentreStore.self) private var store
    
    @State private var showPlayer = false
    @State private var selectedSound: AsmrSound?
    @State private var favouriteNames: Set<String> = []
    
    private static let favouritesKey = "asmr_favourite_names"
    
    // Convert hex string to Color
    private var playlistColor: Color {
        Color(hex: playlist.placeholderColorHex)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                
                VStack(spacing: 12) {
                    ForEach(playlist.sounds, id: \.name) { sound in
                        soundRow(sound)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFavourites()
            saveAsRecentPlaylist()
        }
        .navigationDestination(isPresented: $showPlayer) {
            if let sound = selectedSound {
                ASMRPlayerView(
                    sound: sound,
                    isFavourite: favouriteNames.contains(sound.name),
                    onToggleFavourite: { toggleFavourite(sound.name) }
                )
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Header Image Placeholder
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(playlistColor.gradient)
                .frame(width: 240, height: 240)
                .shadow(color: playlistColor.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.top, 20)
            
            VStack(spacing: 8) {
                Text(playlist.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text(playlist.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(playlist.purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            HStack(spacing: 16) {
                Button {
                    if let first = playlist.sounds.first {
                        play(sound: first)
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    if let random = playlist.sounds.randomElement() {
                        play(sound: random)
                    }
                } label: {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private func soundRow(_ sound: AsmrSound) -> some View {
        Button {
            play(sound: sound)
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "waveform")
                            .foregroundStyle(.secondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(sound.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func play(sound: AsmrSound) {
        selectedSound = sound
        showPlayer = true
        saveAsRecentSound(sound)
    }
    
    private func loadFavourites() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.favouritesKey) {
            favouriteNames = Set(saved)
        }
    }
    
    private func toggleFavourite(_ name: String) {
        if favouriteNames.contains(name) {
            favouriteNames.remove(name)
        } else {
            favouriteNames.insert(name)
        }
        UserDefaults.standard.set(Array(favouriteNames), forKey: Self.favouritesKey)
    }
    
    private func saveAsRecentPlaylist() {
        // Save just the ID to UserDefaults
        UserDefaults.standard.set(playlist.id.uuidString, forKey: "recent_asmr_playlist_id")
    }
    
    private func saveAsRecentSound(_ sound: AsmrSound) {
        // Save up to 10 recently played sounds
        let key = "recent_asmr_sounds"
        var recents: [AsmrSound] = []
        
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([AsmrSound].self, from: data) {
            recents = saved
        }
        
        // Remove if it already exists to put it at the top
        recents.removeAll { $0.name == sound.name }
        recents.insert(sound, at: 0)
        
        // Keep only top 10
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        
        if let encoded = try? JSONEncoder().encode(recents) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

