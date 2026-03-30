//
//  ASMRPlayerView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Constants

private let accentOrange = Color("CalmOrange")

// MARK: - ASMRPlayerView

@available(iOS 17.0, *)
struct ASMRPlayerView: View {

    let sound: AsmrSound
    let isFavourite: Bool
    let onToggleFavourite: () -> Void

    private var store: CalmCentreStore { CalmCentreStore.shared }
    private var audioService: ASMRAudioService { ASMRAudioService.shared }
    @Environment(\.dismiss) private var dismiss

    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var volume: Double = 0.5
    @State private var isSeeking = false
    @State private var isMuted = false

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // 1 ── Artwork
            artwork

            Spacer().frame(height: 32)

            // 2 ── Title + Favourite
            titleRow
                .padding(.horizontal, 28)

            Spacer().frame(height: 20)

            // 3 ── Progress bar + times
            progressSection
                .padding(.horizontal, 28)

            Spacer().frame(height: 36)

            // 4 ── Playback controls
            playbackControls

            Spacer().frame(height: 36)

            // 5 ── Volume slider
            volumeSlider
                .padding(.horizontal, 28)

            Spacer()
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if store.activeAsmrSound?.id == sound.id, audioService.isPlaying {
                isPlaying = true
                duration = audioService.duration
                currentTime = audioService.currentTime
                startTimer()
            } else {
                startPlaying()
            }
        }
        .onDisappear { stopTimer() }
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension ASMRPlayerView {

    // MARK: Artwork

    var artwork: some View {
        Image(sound.imageUrl.isEmpty ? "asmr_rain" : sound.imageUrl)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.main.bounds.width - 56,
                   height: UIScreen.main.bounds.width - 56)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    // MARK: Title Row

    var titleRow: some View {
        HStack(alignment: .center) {
            Text(sound.name)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)

            Spacer()

            Button { onToggleFavourite() } label: {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavourite ? accentOrange : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Progress Section (Interactive Seek Slider)

    var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        currentTime = newValue
                        audioService.seek(to: newValue)
                    }
                ),
                in: 0...max(duration, 1)
            ) { editing in
                isSeeking = editing
                if !editing {
                    audioService.seek(to: currentTime)
                }
            }
            .tint(Color(.systemGray))

            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text("-\(formatTime(max(0, duration - currentTime)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: Playback Controls

    var playbackControls: some View {
        HStack(spacing: 44) {
            // Sound icon – tap to mute/unmute
            Button {
                isMuted.toggle()
                audioService.setVolume(isMuted ? 0 : Float(volume))
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            // Play / Pause
            Button {
                if isPlaying { pausePlaying() }
                else { resumePlaying() }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(accentOrange))
            }
            .buttonStyle(.plain)

            // Replay – reset to start
            Button {
                currentTime = 0
                audioService.seek(to: 0)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Volume Slider

    var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $volume, in: 0...1)
                .tint(Color(.systemGray))
                .onChange(of: volume) { _, newValue in
                    audioService.setVolume(Float(newValue))
                }

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Helpers

    func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Playback Logic

@available(iOS 17.0, *)
private extension ASMRPlayerView {

    func startPlaying() {
        store.playAsmrSound(sound)
        audioService.play(soundName: sound.name)
        isPlaying = true
        // Get actual duration from the audio file
        duration = audioService.duration
        currentTime = 0
        startTimer()
    }

    func pausePlaying() {
        audioService.pause()
        isPlaying = false
        stopTimer()
    }

    func resumePlaying() {
        audioService.resume()
        isPlaying = true
        startTimer()
    }

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard !isSeeking else { return }
            currentTime = audioService.currentTime
            duration = audioService.duration

            // Stop at end of track
            if currentTime >= duration, duration > 0 {
                pausePlaying()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
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
    }
}
