import SwiftUI

/// This view provides the full-screen player interface for a selected ASMR sound.
struct ASMRPlayerView: View {

    let sound: AsmrSound
    let isFavourite: Bool
    let onToggleFavourite: () -> Void

    @Environment(\.dismiss) private var dismiss

    // UI state to track playback progress, volume, and playback status
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var volume: Double = 0.5
    @State private var isSeeking = false
    @State private var isMuted = false

    @Environment(CalmCentreStore.self) private var store
    private var audio: ASMRAudioService { ASMRAudioService.shared }

    var body: some View {
        GeometryReader { geo in
            let artworkSize = geo.size.width - 56

            VStack(spacing: 0) {
                Spacer()

                // Sound Artwork: Loads from Supabase URL with a local image fallback
                AsyncImage(url: URL(string: sound.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(sound.imageUrl.isEmpty ? "asmr_rain" : sound.imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color(.systemGray6))
                }
                .frame(width: artworkSize, height: artworkSize)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                Spacer().frame(height: 32)

                // Displays Title and a Heart button for favorites
                titleRow.padding(.horizontal, 28)

                Spacer().frame(height: 20)

                // Shows the progress slider and time (current vs total)
                progressSection.padding(.horizontal, 28)

                Spacer().frame(height: 36)

                // The main Play/Pause, Mute, and Reset buttons
                playbackControls

                Spacer().frame(height: 36)

                // Volume slider for manual adjustment
                volumeSlider.padding(.horizontal, 28)

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // If this exact sound is already playing in the background, sync the UI to it
            if store.activeAsmrSound?.id == sound.id, audio.isPlaying {
                isPlaying = true
                duration = audio.duration
                currentTime = audio.currentTime
                startTimer()
            } else {
                // Otherwise, start playing it from the beginning
                startPlaying()
            }
        }
        .onDisappear { 
            // Stop the UI refresh timer when the user closes the player
            stopTimer() 
        }
    }

    // MARK: - Subviews

    /// Row containing the sound name and the favorite heart toggle
    private var titleRow: some View {
        HStack {
            Text(sound.name)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)

            Spacer()

            Button { onToggleFavourite() } label: {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavourite ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    /// Progress slider and time labels (formatted as 0:00)
    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        currentTime = newValue
                        audio.seek(to: newValue)
                    }
                ),
                in: 0...max(duration, 1)
            ) { editing in
                isSeeking = editing
                // When the user stops dragging, seek to the final position
                if !editing { audio.seek(to: currentTime) }
            }
            .tint(Color(.systemGray))

            HStack {
                Text(formatTime(currentTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                // Shows time remaining
                Text("-\(formatTime(max(0, duration - currentTime)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    /// Primary playback buttons (Mute, Play/Pause, Reset)
    private var playbackControls: some View {
        HStack(spacing: 44) {
            // Mute / Unmute toggle
            Button {
                isMuted.toggle()
                audio.setVolume(isMuted ? 0 : Float(volume))
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            // Large center Play/Pause button
            Button {
                isPlaying ? pausePlaying() : resumePlaying()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Reset button to go back to the beginning
            Button {
                currentTime = 0
                audio.seek(to: 0)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    /// Simple slider to adjust the player volume
    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $volume, in: 0...1)
                .tint(Color(.systemGray))
                .onChange(of: volume) { _, newValue in
                    audio.setVolume(Float(newValue))
                }

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Converts raw seconds into a readable string like "3:45"
    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Playback Logic

    /// Starts a new playback session for the sound
    private func startPlaying() {
        store.playAsmrSound(sound) // Tell the store to log this sound as active
        audio.play(sound: sound)
        isPlaying = true
        duration = audio.duration
        currentTime = 0
        startTimer()
    }

    private func pausePlaying() {
        audio.pause()
        isPlaying = false
        stopTimer()
    }

    private func resumePlaying() {
        audio.resume()
        isPlaying = true
        startTimer()
    }

    /// Starts a timer that refreshes the UI progress every quarter-second
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            Task { @MainActor in
                guard !isSeeking else { return }
                currentTime = audio.currentTime
                duration = audio.duration
                // Automatically pause if the sound reaches the end
                if currentTime >= duration, duration > 0 { pausePlaying() }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        ASMRPlayerView(
            sound: AsmrSound(
                name: "Nature & Calm",
                description: "Recommended for Focus",
                category: "Nature",
                audioUrl: "",
                imageUrl: "asmr_hero",
                durationSeconds: 300
            ),
            isFavourite: false,
            onToggleFavourite: {}
        )
        .environment(CalmCentreStore.shared)
        .environment(UserStore.shared)
    }
}
