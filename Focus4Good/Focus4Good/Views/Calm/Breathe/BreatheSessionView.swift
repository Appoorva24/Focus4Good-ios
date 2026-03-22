//
//  BreatheSessionView.swift
//  Focus4Good
//
//  Created by Shreya on 22/03/26.
//

import SwiftUI

// MARK: - Breathing Phase

private enum BreathingPhase: String {
    case breatheIn  = "Breathe In"
    case hold       = "Hold"
    case breatheOut = "Breathe Out"
    case idle       = "Get Ready"

    var duration: Int {
        switch self {
        case .breatheIn:  return 4
        case .hold:       return 7
        case .breatheOut: return 8
        case .idle:       return 0
        }
    }

    var next: BreathingPhase {
        switch self {
        case .idle:       return .breatheIn
        case .breatheIn:  return .hold
        case .hold:       return .breatheOut
        case .breatheOut: return .breatheIn
        }
    }

    /// Scale factor for the breathing circle.
    var circleScale: CGFloat {
        switch self {
        case .breatheIn:  return 1.0
        case .hold:       return 1.0
        case .breatheOut: return 0.5
        case .idle:       return 0.5
        }
    }
}

// MARK: - Constants

private let accentOrange = Color("CalmOrange")
private let cycleOptions = Array(1...8)
private let defaultCycles = 4

// MARK: - BreatheSessionView

@available(iOS 17.0, *)
struct BreatheSessionView: View {

    private var store: CalmCentreStore { CalmCentreStore.shared }

    @Environment(\.dismiss) private var dismiss

    // State
    @State private var selectedCycles = defaultCycles
    @State private var currentCycle = 1
    @State private var phase: BreathingPhase = .idle
    @State private var countdown = 0
    @State private var isRunning = false
    @State private var showCompletion = false

    // Timer
    @State private var timer: Timer?

    // Placeholder user ID
    private let userId = UUID()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                breathingCircle
                Spacer()
                cycleProgress
                    .padding(.bottom, 24)
                actionButton
                    .padding(.bottom, 48)
            }

            // Completion popup
            if showCompletion {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        .navigationTitle("Breathe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                cycleMenu
            }
        }
        .onDisappear { stopTimer() }
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension BreatheSessionView {

    // MARK: Breathing Circle

    var breathingCircle: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(accentOrange.opacity(0.15), lineWidth: 8)
                    .frame(width: 220, height: 220)

                // Animated circle
                Circle()
                    .fill(accentOrange.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .scaleEffect(phase.circleScale)
                    .animation(.easeInOut(duration: Double(phase.duration)), value: phase)

                // Inner content
                VStack(spacing: 8) {
                    Text(phase.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if isRunning {
                        Text("\(countdown)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(accentOrange)
                            .contentTransition(.numericText())
                    }
                }
            }
        }
    }

    // MARK: Cycle Progress

    var cycleProgress: some View {
        VStack(spacing: 12) {
            Text("Cycle \(currentCycle) of \(selectedCycles)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(1...selectedCycles, id: \.self) { index in
                    Circle()
                        .fill(index <= currentCycle ? accentOrange : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
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

    // MARK: Cycle Menu

    var cycleMenu: some View {
        Menu {
            ForEach(cycleOptions, id: \.self) { count in
                Button {
                    if !isRunning {
                        selectedCycles = count
                    }
                } label: {
                    HStack {
                        Text("\(count) Cycle\(count == 1 ? "" : "s")")
                        if count == defaultCycles {
                            Text("Recommended")
                        }
                        if count == selectedCycles {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(selectedCycles)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Image(systemName: "repeat.circle.fill")
                    .font(.title3)
            }
            .foregroundStyle(accentOrange)
        }
        .disabled(isRunning)
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

                Text("Well Done!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You completed \(selectedCycles) cycle\(selectedCycles == 1 ? "" : "s") of 4-7-8 breathing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ \(selectedCycles * 10) Focus Points")
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
}

// MARK: - Session Logic

@available(iOS 17.0, *)
private extension BreatheSessionView {

    func startSession() {
        currentCycle = 1
        startPhase(.breatheIn)
        isRunning = true
    }

    func stopSession() {
        stopTimer()
        phase = .idle
        countdown = 0
        isRunning = false
        currentCycle = 1
    }

    func startPhase(_ newPhase: BreathingPhase) {
        phase = newPhase
        countdown = newPhase.duration
        startTimer()
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
        guard countdown > 1 else {
            advancePhase()
            return
        }
        countdown -= 1
    }

    func advancePhase() {
        let next = phase.next

        // If we just finished exhale, that's one full cycle
        if phase == .breatheOut {
            if currentCycle >= selectedCycles {
                // All cycles done
                completeSession()
                return
            }
            currentCycle += 1
        }

        startPhase(next)
    }

    func completeSession() {
        stopTimer()
        isRunning = false

        let totalSeconds = selectedCycles * (4 + 7 + 8)
        Task {
            await store.logBreathingSession(
                userId: userId,
                techniqueName: "4-7-8 Breathing",
                cyclesCompleted: selectedCycles,
                durationSeconds: totalSeconds
            )
        }

        showCompletion = true
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        BreatheSessionView()
    }
}
