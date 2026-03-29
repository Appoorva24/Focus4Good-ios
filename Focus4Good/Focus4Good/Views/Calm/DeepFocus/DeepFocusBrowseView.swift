//
//  DeepFocusBrowseView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Meditation Phase

struct MeditationPhaseData: Identifiable {
    let id = UUID()
    let title: String
    let instruction: String
    let durationSeconds: Int
}

// MARK: - 5-Minute Guided Meditation Phases

private let guidedPhases: [MeditationPhaseData] = [
    .init(title: "Welcome",   instruction: "Find a comfortable position and close your eyes",  durationSeconds: 30),
    .init(title: "Settle",    instruction: "Take three deep breaths to arrive in this moment",  durationSeconds: 35),
    .init(title: "Breathe",   instruction: "Let your racing thoughts give a pause",             durationSeconds: 40),
    .init(title: "Notice",    instruction: "Feel the air entering your nostrils gently",         durationSeconds: 45),
    .init(title: "Follow",    instruction: "Follow each breath from inhale to exhale",           durationSeconds: 45),
    .init(title: "Deepen",    instruction: "Sink deeper into stillness with each exhale",        durationSeconds: 40),
    .init(title: "Rest",      instruction: "You are safe. There is nothing you need to do",      durationSeconds: 35),
    .init(title: "Return",    instruction: "Slowly bring awareness back to the room",            durationSeconds: 30),
]

// MARK: - Constants

private let accentOrange = Color("CalmOrange")
private let totalSessionSeconds = 300 // 5 minutes

// MARK: - DeepFocusBrowseView (Single Screen)

@available(iOS 17.0, *)
struct DeepFocusBrowseView: View {

    private var store: CalmCentreStore { CalmCentreStore.shared }
    private var voiceService: MeditationAudioService { MeditationAudioService.shared }
    @Environment(\.dismiss) private var dismiss

    // Session state
    @State private var isPlaying = false
    @State private var hasStarted = false
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isMuted = false
    @State private var showCompletion = false
    @State private var currentPhaseIndex = 0

    private let userId = UUID()

    // Scale phases to fit 5 minutes exactly
    private var scaledPhases: [(phase: MeditationPhaseData, duration: Int)] {
        let originalTotal = guidedPhases.reduce(0) { $0 + $1.durationSeconds }
        guard originalTotal > 0 else { return [] }
        let scale = Double(totalSessionSeconds) / Double(originalTotal)
        return guidedPhases.map { ($0, max(Int(Double($0.durationSeconds) * scale), 5)) }
    }

    private var currentInstruction: String {
        guard currentPhaseIndex < scaledPhases.count else {
            return "Session complete"
        }
        return scaledPhases[currentPhaseIndex].phase.instruction
    }

    private var remaining: TimeInterval {
        max(0, Double(totalSessionSeconds) - elapsed)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Orange circle with meditation icon
                meditationOrb

                Spacer().frame(height: 40)

                // Guided instruction text
                Text(hasStarted ? currentInstruction : "Tap play to begin your guided meditation")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: currentPhaseIndex)

                Spacer().frame(height: 40)

                // Progress slider + times
                progressSection
                    .padding(.horizontal, 28)

                Spacer().frame(height: 40)

                // Playback controls
                playbackControls

                Spacer()
            }

            if showCompletion {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        .navigationTitle("Guided Meditation")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear {
            stopTimer()
            voiceService.stopAll()
        }
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension DeepFocusBrowseView {

    // MARK: Meditation Orb

    var meditationOrb: some View {
        ZStack {
            // Soft glow behind
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentOrange.opacity(0.25), accentOrange.opacity(0.0)],
                        center: .center,
                        startRadius: 70,
                        endRadius: 160
                    )
                )
                .frame(width: 280, height: 280)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(isPlaying ? (phase ? 1.08 : 0.95) : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 4.0)
                }

            // Main orange circle
            Circle()
                .fill(accentOrange.opacity(0.85))
                .frame(width: 180, height: 180)
                .shadow(color: accentOrange.opacity(0.25), radius: 20, x: 0, y: 8)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(isPlaying ? (phase ? 1.04 : 0.96) : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 4.0)
                }

            // Meditation icon
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 44))
                .foregroundStyle(.white)
        }
    }

    // MARK: Progress Section

    var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { elapsed },
                    set: { _ in }  // Read-only for meditation
                ),
                in: 0...Double(totalSessionSeconds)
            )
            .tint(Color(.systemGray))
            .disabled(true)

            // Time labels
            HStack {
                Text(formatTime(elapsed))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text("-\(formatTime(remaining))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: Playback Controls

    var playbackControls: some View {
        HStack(spacing: 44) {
            // Sound icon – mute/unmute
            Button {
                isMuted.toggle()
                if isMuted {
                    voiceService.stopAll()
                }
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(isMuted ? .secondary : accentOrange)
            }
            .buttonStyle(.plain)

            // Play / Pause
            Button {
                if isPlaying {
                    pauseSession()
                } else if hasStarted {
                    resumeSession()
                } else {
                    startSession()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(accentOrange))
                    .shadow(color: accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Reset
            Button {
                resetSession()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(accentOrange)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Completion Overlay

    var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showCompletion = false
                    dismiss()
                }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(accentOrange)

                Text("Namaste 🙏")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You completed a 5-minute\nGuided Meditation session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 50 Focus Points")
                    .font(.headline)
                    .foregroundStyle(accentOrange)

                Button {
                    showCompletion = false
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule()
                                .fill(accentOrange)
                                .shadow(color: accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }

    // MARK: Helpers

    func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Session Logic

@available(iOS 17.0, *)
private extension DeepFocusBrowseView {

    func startSession() {
        elapsed = 0
        currentPhaseIndex = 0
        hasStarted = true
        isPlaying = true

        // AI voice welcome
        if !isMuted {
            voiceService.speakWelcome(meditationName: "Guided Meditation", durationMinutes: 5)
            // Speak first phase after a short delay for welcome
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if isPlaying && !isMuted && currentPhaseIndex < scaledPhases.count {
                    voiceService.speakPhase(
                        title: scaledPhases[currentPhaseIndex].phase.title,
                        instruction: scaledPhases[currentPhaseIndex].phase.instruction
                    )
                }
            }
        }

        startTimer()
    }

    func pauseSession() {
        isPlaying = false
        stopTimer()
        if !isMuted {
            voiceService.stopAll()
        }
    }

    func resumeSession() {
        isPlaying = true
        startTimer()

        if !isMuted && currentPhaseIndex < scaledPhases.count {
            voiceService.speakPhase(
                title: scaledPhases[currentPhaseIndex].phase.title,
                instruction: scaledPhases[currentPhaseIndex].phase.instruction
            )
        }
    }

    func resetSession() {
        stopTimer()
        voiceService.stopAll()
        elapsed = 0
        currentPhaseIndex = 0
        hasStarted = false
        isPlaying = false
    }

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        elapsed += 1

        // Check if we need to advance to the next phase
        var cumulativeTime = 0
        for (index, scaled) in scaledPhases.enumerated() {
            cumulativeTime += scaled.duration
            if Int(elapsed) < cumulativeTime {
                if index != currentPhaseIndex {
                    currentPhaseIndex = index
                    // Speak new phase
                    if !isMuted {
                        voiceService.speakPhase(
                            title: scaled.phase.title,
                            instruction: scaled.phase.instruction
                        )
                    }
                }
                break
            }
        }

        // Check if session is complete
        if Int(elapsed) >= totalSessionSeconds {
            completeSession()
        }
    }

    func completeSession() {
        stopTimer()
        isPlaying = false
        hasStarted = false

        if !isMuted {
            voiceService.speakCompletion(meditationName: "Guided Meditation", durationMinutes: 5)
        }

        Task {
            await store.logGuidedMeditationSession(
                userId: userId,
                meditationName: "Guided Meditation",
                durationSeconds: totalSessionSeconds
            )
        }

        showCompletion = true
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        DeepFocusBrowseView()
    }
}
