//
//  DeepFocusSessionView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import SwiftUI

// MARK: - Constants

private let accentOrange = Color("CalmOrange")

// MARK: - DeepFocusSessionView

@available(iOS 17.0, *)
struct DeepFocusSessionView: View {

    let meditationName: String
    let icon: String
    let phases: [MeditationPhaseData]
    let totalMinutes: Int

    private var store: CalmCentreStore { CalmCentreStore.shared }
    @Environment(\.dismiss) private var dismiss

    // Session state
    @State private var isRunning = false
    @State private var currentPhaseIndex = 0
    @State private var phaseCountdown = 0
    @State private var totalElapsed = 0
    @State private var showCompletion = false
    @State private var timer: Timer?

    private let userId = UUID()

    // Scale phase durations to fit chosen total time
    private var scaledPhases: [(phase: MeditationPhaseData, duration: Int)] {
        let originalTotal = phases.reduce(0) { $0 + $1.durationSeconds }
        let targetTotal = totalMinutes * 60
        guard originalTotal > 0 else { return [] }
        let scale = Double(targetTotal) / Double(originalTotal)
        return phases.map { ($0, max(Int(Double($0.durationSeconds) * scale), 5)) }
    }

    private var currentScaled: (phase: MeditationPhaseData, duration: Int) {
        scaledPhases[min(currentPhaseIndex, max(scaledPhases.count - 1, 0))]
    }

    private var totalDurationSeconds: Int {
        scaledPhases.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                visualAnchor
                guidedText
                    .padding(.top, 32)
                Spacer()
                progressSection
                    .padding(.bottom, 20)
                actionButton
                    .padding(.bottom, 48)
            }

            if showCompletion {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        .navigationTitle(meditationName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTimer() }
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension DeepFocusSessionView {

    // MARK: Visual Anchor

    var visualAnchor: some View {
        ZStack {
            // Outer ring — breathing pulse
            Circle()
                .stroke(accentOrange.opacity(0.10), lineWidth: 6)
                .frame(width: 220, height: 220)

            // Middle pulsing ring
            Circle()
                .stroke(accentOrange.opacity(0.20), lineWidth: 3)
                .frame(width: 180, height: 180)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(isRunning ? (phase ? 1.08 : 0.92) : 1.0)
                        .opacity(isRunning ? (phase ? 0.3 : 0.1) : 0.15)
                } animation: { _ in
                    .easeInOut(duration: 4.0)
                }

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentOrange.opacity(0.25), accentOrange.opacity(0.05)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 150, height: 150)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(isRunning ? (phase ? 1.12 : 0.88) : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 4.0)
                }

            // Center icon
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(accentOrange)

                if isRunning {
                    Text(formatTime(phaseCountdown))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .frame(width: 240, height: 240)
    }

    // MARK: Guided Text

    var guidedText: some View {
        VStack(spacing: 12) {
            if isRunning {
                Text(currentScaled.phase.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .contentTransition(.opacity)

                Text(currentScaled.phase.instruction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .contentTransition(.opacity)
            } else {
                Text("Ready")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Find a comfortable position.\nPress Start when you're ready.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: currentPhaseIndex)
        .padding(.horizontal, 32)
        .frame(minHeight: 100)
    }

    // MARK: Progress

    var progressSection: some View {
        VStack(spacing: 12) {
            // Phase progress dots
            HStack(spacing: 5) {
                ForEach(0..<scaledPhases.count, id: \.self) { i in
                    Capsule()
                        .fill(i < currentPhaseIndex ? accentOrange :
                              i == currentPhaseIndex && isRunning ? accentOrange.opacity(0.5) :
                              Color(.systemGray4))
                        .frame(maxWidth: .infinity, maxHeight: 4)
                }
            }
            .padding(.horizontal, 32)

            // Time info
            HStack {
                Text(formatTime(totalElapsed))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(totalMinutes) min session")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatTime(totalDurationSeconds))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: Action Button

    var actionButton: some View {
        Button {
            if isRunning {
                stopSession()
            } else {
                startSession()
            }
        } label: {
            Text(isRunning ? "Stop" : "Start")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 160, height: 52)
                .background(
                    Capsule()
                        .fill(isRunning ? Color(.systemGray3) : accentOrange)
                )
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

                Text("You completed a \(totalMinutes)-minute \(meditationName) meditation")
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
                        .background(Capsule().fill(accentOrange))
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

    func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Session Logic

@available(iOS 17.0, *)
private extension DeepFocusSessionView {

    func startSession() {
        currentPhaseIndex = 0
        totalElapsed = 0
        phaseCountdown = currentScaled.duration
        isRunning = true
        startTimer()
    }

    func stopSession() {
        stopTimer()
        isRunning = false
        currentPhaseIndex = 0
        totalElapsed = 0
        phaseCountdown = 0
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
        totalElapsed += 1

        guard phaseCountdown > 1 else {
            advancePhase()
            return
        }
        phaseCountdown -= 1
    }

    func advancePhase() {
        if currentPhaseIndex >= scaledPhases.count - 1 {
            completeSession()
        } else {
            currentPhaseIndex += 1
            phaseCountdown = currentScaled.duration
        }
    }

    func completeSession() {
        stopTimer()
        isRunning = false

        Task {
            await store.logGuidedMeditationSession(
                userId: userId,
                meditationName: meditationName,
                durationSeconds: totalElapsed
            )
        }

        showCompletion = true
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        DeepFocusSessionView(
            meditationName: "Breath Awareness",
            icon: "wind",
            phases: [
                .init(title: "Settle", instruction: "Close your eyes.\nBreathe deeply.", durationSeconds: 10),
                .init(title: "Focus", instruction: "Follow your breath.", durationSeconds: 20),
                .init(title: "Return", instruction: "Open your eyes.", durationSeconds: 10),
            ],
            totalMinutes: 3
        )
    }
}
