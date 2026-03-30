//
//  SensorySootheView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Sound Card Data

/// Local data for each ASMR card – pairs a display image with sound metadata.
private struct ASMRSoundEntry: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let imageName: String         // Asset catalog image name
    let category: String          // Maps to NoiseProfile in ASMRAudioService
    let durationSeconds: Int
}

private let soundEntries: [ASMRSoundEntry] = [
    .init(name: "Soft Rain",    subtitle: "Light Drizzle",         imageName: "asmr_softrain",    category: "Rain",        durationSeconds: 600),
    .init(name: "Typing",       subtitle: "Mechanical clicks",    imageName: "asmr_typing",      category: "Ambient",     durationSeconds: 600),
    .init(name: "Crinkling",    subtitle: "Crisp and dry sounds", imageName: "asmr_crinkling",   category: "Nature",      durationSeconds: 600),
    .init(name: "Tapping",      subtitle: "Gentle surface touch", imageName: "asmr_tapping",     category: "Ambient",     durationSeconds: 600),
    .init(name: "White Noise",  subtitle: "Background hum",       imageName: "asmr_whitenoise",  category: "White Noise", durationSeconds: 600),
    .init(name: "Forest",       subtitle: "Rustling leaves",      imageName: "asmr_forest",      category: "Nature",      durationSeconds: 600),
]

// MARK: - SensorySootheView

struct SensorySootheView: View {

    private var store: CalmCentreStore { CalmCentreStore.shared }

    @State private var showPlayer = false
    @State private var selectedSound: AsmrSound?
    @State private var favouriteNames: Set<String> = []

    private static let favouritesKey = "asmr_favourite_names"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                heroBanner
                soundList
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ASMR Sounds")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadFavourites() }
        .navigationDestination(isPresented: $showPlayer) {
            if let sound = selectedSound {
                ASMRPlayerView(
                    sound: sound,
                    isFavourite: favouriteNames.contains(sound.name),
                    onToggleFavourite: {
                        toggleFavourite(sound.name)
                    }
                )
            }
        }
    }

    // MARK: - Local Favourite Persistence

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
}

// MARK: - Subviews

private extension SensorySootheView {

    // MARK: Hero Banner (Tappable)

    var heroBanner: some View {
        Button {
            selectedSound = AsmrSound(
                name: "Nature & Calm",
                description: "Recommended for Focus",
                category: "Nature",
                audioUrl: "",
                imageUrl: "asmr_hero",
                durationSeconds: 900
            )
            showPlayer = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                Image("asmr_hero")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()

                // Gradient for text legibility
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Nature & Calm")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Recommended for Focus")
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

    // MARK: Sound List (Vertical, like Apple Music)

    var soundList: some View {
        VStack(spacing: 12) {
            ForEach(soundEntries) { entry in
                soundRow(entry)
            }
        }
    }

    // MARK: Sound Row

    func soundRow(_ entry: ASMRSoundEntry) -> some View {
        Button {
            selectedSound = AsmrSound(
                name: entry.name,
                description: entry.subtitle,
                category: entry.category,
                audioUrl: "",
                imageUrl: entry.imageName,
                durationSeconds: entry.durationSeconds
            )
            showPlayer = true
        } label: {
            HStack(spacing: 14) {
                // Thumbnail
                Image(entry.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(entry.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Chevron
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

// MARK: - Preview

#Preview {
    NavigationStack {
        SensorySootheView()
    }
}
