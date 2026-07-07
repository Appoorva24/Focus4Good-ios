import SwiftUI

struct SensorySootheView: View {

    @Environment(CalmCentreStore.self) private var store

    @State private var selectedSound: AsmrSound?
    @State private var favouriteNames: Set<String> = []
    
    // New State for Recents
    @State private var recentPlaylist: ASMRPlaylist?
    @State private var recentSounds: [AsmrSound] = []

    private static let favouritesKey = "asmr_favourite_names"
    private static let recentPlaylistKey = "recent_asmr_playlist_id"
    private static let recentSoundsKey = "recent_asmr_sounds"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                
                // 1. Top Section: 5 Playlists (Horizontally Scrollable)
                playlistsSection
                
                // 2. Middle Section: Recent Playlist
                if recentPlaylist != nil {
                    recentPlaylistSection
                }
                
                // 3. Bottom Section: Recently Played ASMR Sounds
                if !recentSounds.isEmpty {
                    recentlyPlayedSoundsSection
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationTitle("ASMR Sounds")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { 
            store.activeASMRViewsCount += 1
            loadFavourites()
            loadRecents()
        }
        .onDisappear {
            store.activeASMRViewsCount -= 1
        }
    }

    // MARK: - Data Loading
    
    private func loadFavourites() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.favouritesKey) {
            favouriteNames = Set(saved)
        }
    }
    
    private func loadRecents() {
        // Load recent playlist
        if let savedIdString = UserDefaults.standard.string(forKey: Self.recentPlaylistKey),
           let savedId = UUID(uuidString: savedIdString) {
            recentPlaylist = ASMRData.playlists.first(where: { $0.id == savedId })
        }
        
        // Load recent sounds
        if let data = UserDefaults.standard.data(forKey: Self.recentSoundsKey),
           let saved = try? JSONDecoder().decode([AsmrSound].self, from: data) {
            recentSounds = saved
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

    // MARK: - Subviews

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ASMRData.playlists) { playlist in
                        NavigationLink(destination: ASMRPlaylistDetailView(playlist: playlist)) {
                            playlistCard(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16) // Added vertical padding so shadows aren't clipped during scroll
            }

        }
    }
    
    private func playlistCard(playlist: ASMRPlaylist) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background (Image or Placeholder Color)
            if !playlist.coverImageName.isEmpty {
                Image(playlist.coverImageName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect((playlist.coverImageName == "stress" || playlist.coverImageName == "anxiety") ? 1.15 : 1.0)
                    .frame(width: 280, height: 280)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(hex: playlist.placeholderColorHex).gradient)
            }
            
            // Gradient Overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
                Text(playlist.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: playlist.placeholderColorHex).opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private var recentPlaylistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jump Back In")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let playlist = recentPlaylist {
                NavigationLink(destination: ASMRPlaylistDetailView(playlist: playlist)) {
                    HStack(spacing: 16) {
                        if !playlist.coverImageName.isEmpty {
                            Image(playlist.coverImageName)
                                .resizable()
                                .scaledToFill()
                                .scaleEffect((playlist.coverImageName == "stress" || playlist.coverImageName == "anxiety") ? 1.15 : 1.0)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: playlist.placeholderColorHex).gradient)
                                .frame(width: 80, height: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Recent Playlist")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentlyPlayedSoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Played Sounds")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(recentSounds, id: \.name) { sound in
                    soundRow(sound)
                }
            }
            .padding(.horizontal)
        }
    }

    private func soundRow(_ sound: AsmrSound) -> some View {
        Button {
            selectedSound = sound
            store.activeAsmrSound = sound
            store.showGlobalASMRPlayer = true
        } label: {
            HStack(spacing: 14) {
                if !sound.imageUrl.isEmpty {
                    Image(sound.imageUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "waveform")
                                .foregroundStyle(.secondary)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(sound.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(sound.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SensorySootheView()
            .environment(CalmCentreStore.shared)
    }
}
