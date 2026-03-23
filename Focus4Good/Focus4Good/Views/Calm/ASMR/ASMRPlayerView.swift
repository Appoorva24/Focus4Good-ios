//
//  ASMRPlayerView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Constants

private let accentOrange = Color("CalmOrange")

private func iconForCategory(_ category: String) -> String {
    switch category {
    case "Nature":      return "leaf.fill"
    case "Rain":        return "cloud.rain.fill"
    case "Ambient":     return "flame.fill"
    case "White Noise": return "waveform.path"
    default:            return "speaker.wave.3.fill"
    }
}

// MARK: - ASMRPlayerView

@available(iOS 17.0, *)
struct ASMRPlayerView: View {

    let sound: AsmrSound
    let isFavourite: Bool
    let onToggleFavourite: () -> Void

    private var store: CalmCentreStore { CalmCentreStore.shared }
    @Environment(\.dismiss) private var dismiss

    @State private var isPlaying = false
    @State private var elapsed = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                iconArea
                soundInfo
                    .padding(.top, 28)
                waveformBars
                    .padding(.top, 32)
                Spacer()
                timeDisplay
                    .padding(.bottom, 20)
                controls
                    .padding(.bottom, 48)
            }
        }
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { onToggleFavourite() } label: {
                    Image(systemName: isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavourite ? accentOrange : .secondary)
                }
            }
        }
        .onAppear {
            if store.activeAsmrSound?.id == sound.id, ASMRAudioService.shared.isPlaying {
                isPlaying = true
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

    // MARK: Icon

    var iconArea: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(accentOrange.opacity(0.12), lineWidth: 6)
                .frame(width: 200, height: 200)

            // Animated background
            Circle()
                .fill(accentOrange.opacity(0.15))
                .frame(width: 160, height: 160)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(isPlaying ? (phase ? 1.08 : 0.95) : 1.0)
                        .opacity(isPlaying ? (phase ? 0.25 : 0.12) : 0.15)
                } animation: { _ in
                    .easeInOut(duration: 3.0)
                }

            // Category icon
            Image(systemName: iconForCategory(sound.category))
                .font(.system(size: 48))
                .foregroundStyle(accentOrange)
        }
        .frame(width: 220, height: 220)
    }

    // MARK: Sound Info

    var soundInfo: some View {
        VStack(spacing: 8) {
            Text(sound.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(sound.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text(sound.category)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(accentOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(accentOrange.opacity(0.12))
                )
                .padding(.top, 4)
        }
    }

    // MARK: Waveform Bars

    var waveformBars: some View {
        HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { i in
                let baseHeight: CGFloat = CGFloat([14, 22, 18, 28, 16, 24, 12][i])
                let lowHeight: CGFloat = CGFloat([6, 8, 6, 10, 6, 8, 4][i])

                RoundedRectangle(cornerRadius: 3)
                    .fill(accentOrange.opacity(isPlaying ? 0.8 : 0.3))
                    .frame(width: 6)
                    .phaseAnimator([false, true]) { content, phase in
                        content.frame(height: isPlaying
                                      ? (phase ? baseHeight : lowHeight)
                                      : lowHeight)
                    } animation: { _ in
                        .easeInOut(duration: 0.5 + Double(i) * 0.1)
                    }
            }
        }
        .frame(height: 36)
    }

    // MARK: Time Display

    var timeDisplay: some View {
        HStack {
            Text(formatTime(elapsed))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)

                    Capsule()
                        .fill(accentOrange)
                        .frame(width: progressWidth(in: geo.size.width), height: 4)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 20)

            Text(formatTime(sound.durationSeconds))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 32)
    }

    func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard sound.durationSeconds > 0 else { return 0 }
        let fraction = CGFloat(elapsed) / CGFloat(sound.durationSeconds)
        return min(fraction, 1.0) * totalWidth
    }

    // MARK: Controls

    var controls: some View {
        HStack(spacing: 32) {
            // Restart
            Button {
                elapsed = 0
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, height: 48)
            }

            // Play / Pause
            Button {
                if isPlaying {
                    pausePlaying()
                } else {
                    resumePlaying()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(accentOrange)
                    )
            }

            // Stop & dismiss
            Button {
                stopPlaying()
                dismiss()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, height: 48)
            }
        }
    }

    // MARK: Helpers

    func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Playback Logic

@available(iOS 17.0, *)
private extension ASMRPlayerView {

    func startPlaying() {
        store.playAsmrSound(sound)
        isPlaying = true
        elapsed = 0
        startTimer()
    }

    func pausePlaying() {
        store.pauseAsmrSound()
        isPlaying = false
        stopTimer()
    }

    func resumePlaying() {
        store.resumeAsmrSound()
        isPlaying = true
        startTimer()
    }

    func stopPlaying() {
        stopTimer()
        isPlaying = false
        elapsed = 0
        store.stopAsmrSound()
    }

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard elapsed < sound.durationSeconds else {
                stopPlaying()
                return
            }
            elapsed += 1
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
                name: "Forest Rain",
                description: "Gentle rain through a forest canopy",
                category: "Nature",
                audioUrl: "",
                imageUrl: "",
                durationSeconds: 600
            ),
            isFavourite: false,
            onToggleFavourite: {}
        )
    }
}
