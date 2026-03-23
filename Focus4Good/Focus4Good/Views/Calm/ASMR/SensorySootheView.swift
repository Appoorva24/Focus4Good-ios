//
//  SensorySootheView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Sample Data

private let sampleSounds: [AsmrSound] = [
    .init(name: "Forest Rain",
          description: "Gentle rain falling through a dense forest canopy",
          category: "Nature", audioUrl: "", imageUrl: "", durationSeconds: 600),
    .init(name: "Ocean Waves",
          description: "Rhythmic waves crashing softly on a sandy shore",
          category: "Nature", audioUrl: "", imageUrl: "", durationSeconds: 900),
    .init(name: "Thunderstorm",
          description: "Distant thunder with steady rainfall on a tin roof",
          category: "Rain", audioUrl: "", imageUrl: "", durationSeconds: 1200),
    .init(name: "Light Drizzle",
          description: "A calm drizzle on a quiet afternoon",
          category: "Rain", audioUrl: "", imageUrl: "", durationSeconds: 480),
    .init(name: "Crackling Fire",
          description: "A warm fireplace crackling on a cold evening",
          category: "Ambient", audioUrl: "", imageUrl: "", durationSeconds: 720),
    .init(name: "Coffee Shop",
          description: "Soft background chatter and clinking cups",
          category: "Ambient", audioUrl: "", imageUrl: "", durationSeconds: 1800),
    .init(name: "Pink Noise",
          description: "Balanced static that calms the restless mind",
          category: "White Noise", audioUrl: "", imageUrl: "", durationSeconds: 600),
    .init(name: "Brown Noise",
          description: "Deep, low rumble that promotes deep focus",
          category: "White Noise", audioUrl: "", imageUrl: "", durationSeconds: 600),
]

private let categories = ["All", "Nature", "Rain", "Ambient", "White Noise"]

// MARK: - Category Icon Mapping

private func iconForCategory(_ category: String) -> String {
    switch category {
    case "Nature":      return "leaf.fill"
    case "Rain":        return "cloud.rain.fill"
    case "Ambient":     return "flame.fill"
    case "White Noise": return "waveform.path"
    default:            return "speaker.wave.3.fill"
    }
}

// MARK: - Constants

private let accentOrange = Color("CalmOrange")

// MARK: - SensorySootheView

@available(iOS 17.0, *)
struct SensorySootheView: View {

    private var store: CalmCentreStore { CalmCentreStore.shared }

    @State private var selectedCategory = "All"
    @State private var favouriteIds: Set<UUID> = []
    @State private var selectedSound: AsmrSound?
    @State private var showPlayer = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var filteredSounds: [AsmrSound] {
        if selectedCategory == "All" { return sampleSounds }
        return sampleSounds.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    categoryStrip
                    soundGrid
                }
                .padding(.horizontal)
                .padding(.bottom, store.activeAsmrSound != nil ? 100 : 32)
            }
            .background(Color(.systemGroupedBackground))

            // Now Playing mini-bar
            if let active = store.activeAsmrSound {
                nowPlayingBar(sound: active)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.activeAsmrSound != nil)
        .navigationDestination(isPresented: $showPlayer) {
            if let sound = selectedSound {
                ASMRPlayerView(sound: sound, isFavourite: favouriteIds.contains(sound.id)) {
                    toggleFavourite(sound.id)
                }
            }
        }
        .navigationTitle("Sensory Soothe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension SensorySootheView {

    // MARK: Header

    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 44))
                .foregroundStyle(accentOrange)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(phase ? 1.06 : 1.0)
                        .opacity(phase ? 1.0 : 0.8)
                } animation: { _ in
                    .easeInOut(duration: 2.5)
                }

            Text("Ambient Sounds")
                .font(.title2)
                .fontWeight(.bold)

            Text("Calm your senses with soothing soundscapes designed for focus and relaxation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: Category Strip

    var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category
                                          ? accentOrange
                                          : accentOrange.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Sound Grid

    var soundGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(filteredSounds) { sound in
                soundCard(sound)
            }
        }
    }

    func soundCard(_ sound: AsmrSound) -> some View {
        Button {
            selectedSound = sound
            showPlayer = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: iconForCategory(sound.category))
                        .font(.title2)
                        .foregroundStyle(accentOrange)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(accentOrange.opacity(0.12))
                        )

                    Spacer()

                    Button {
                        toggleFavourite(sound.id)
                    } label: {
                        Image(systemName: favouriteIds.contains(sound.id)
                              ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundStyle(favouriteIds.contains(sound.id)
                                             ? accentOrange : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(sound.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(formattedDuration(sound.durationSeconds))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Now Playing Bar

    func nowPlayingBar(sound: AsmrSound) -> some View {
        Button {
            selectedSound = sound
            showPlayer = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconForCategory(sound.category))
                    .font(.title3)
                    .foregroundStyle(accentOrange)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(accentOrange.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(sound.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Now Playing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Animated mini waveform
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentOrange)
                            .frame(width: 3)
                            .phaseAnimator([false, true]) { content, phase in
                                content.frame(height: phase ? CGFloat(12 + i * 4) : CGFloat(6 + i * 2))
                            } animation: { _ in
                                .easeInOut(duration: 0.6 + Double(i) * 0.15)
                            }
                    }
                }
                .frame(height: 20)

                Button {
                    store.stopAsmrSound()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(accentOrange))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    func toggleFavourite(_ id: UUID) {
        if favouriteIds.contains(id) {
            favouriteIds.remove(id)
        } else {
            favouriteIds.insert(id)
        }
    }

    func formattedDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        if mins >= 60 {
            return "\(mins / 60)h \(mins % 60)m"
        }
        return "\(mins) min"
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        SensorySootheView()
    }
}
