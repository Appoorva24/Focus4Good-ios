import SwiftUI
import AVFoundation

// MARK: - Breathing Phase

private enum BreathingPhase: String {
    case breatheIn  = "Breathe In"
    case hold       = "Hold"
    case breatheOut = "Breathe Out"
    case idle       = "Get Ready"

    var duration: Int {
        switch self {
        case .breatheIn:  4
        case .hold:       7
        case .breatheOut: 8
        case .idle:       0
        }
    }

    var next: BreathingPhase {
        switch self {
        case .idle:       .breatheIn
        case .breatheIn:  .hold
        case .hold:       .breatheOut
        case .breatheOut: .breatheIn
        }
    }

    var circleScale: CGFloat {
        switch self {
        case .breatheIn, .hold: 1.0
        case .breatheOut, .idle: 0.5
        }
    }
}

// MARK: - Constants

private let cycleOptions = Array(1...8)
private let defaultCycles = 4

// MARK: - BreatheSessionView

struct BreatheSessionView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCycles = defaultCycles
    @State private var currentCycle = 1
    @State private var phase: BreathingPhase = .idle
    @State private var countdown = 0
    @State private var isRunning = false
    @State private var showCompletion = false
    @State private var timer: Timer?

    private let userId = UUID()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                breathingCircle
                Spacer()
                cycleProgress.padding(.bottom, 24)
                actionButton.padding(.bottom, 48)
            }

            if showCompletion {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        .navigationTitle("Breathe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { cycleMenu }
        }
        .onDisappear {
            stopTimer()
            BreatheAudioService.shared.stopAll()
        }
    }

    // MARK: - Subviews

    private var breathingCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 8)
                .frame(width: 220, height: 220)

            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 180, height: 180)
                .scaleEffect(phase.circleScale)
                .animation(.easeInOut(duration: Double(phase.duration)), value: phase)

            VStack(spacing: 8) {
                Text(phase.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)

                if isRunning {
                    Text("\(countdown)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    private var cycleProgress: some View {
        VStack(spacing: 12) {
            Text("Cycle \(currentCycle) of \(selectedCycles)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(1...selectedCycles, id: \.self) { index in
                    Circle()
                        .fill(index <= currentCycle ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var actionButton: some View {
        Button {
            isRunning ? stopSession() : startSession()
        } label: {
            Text(isRunning ? "Stop" : "Start")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 160, height: 52)
                .background(Capsule().fill(isRunning ? Color(.systemGray3) : Color.accentColor))
                .shadow(color: (isRunning ? Color.clear : Color.accentColor.opacity(0.3)), radius: 8, x: 0, y: 4)
        }
    }

    private var cycleMenu: some View {
        Menu {
            ForEach(cycleOptions, id: \.self) { count in
                Button {
                    if !isRunning { selectedCycles = count }
                } label: {
                    HStack {
                        Text("\(count) Cycle\(count == 1 ? "" : "s")")
                        if count == defaultCycles { Text("Recommended") }
                        if count == selectedCycles { Image(systemName: "checkmark") }
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
            .foregroundStyle(Color.accentColor)
        }
        .disabled(isRunning)
    }

    private var completionOverlay: some View {
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
                    .foregroundStyle(Color.accentColor)

                Text("Well Done!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You completed \(selectedCycles) cycle\(selectedCycles == 1 ? "" : "s") of 4-7-8 breathing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ \(selectedCycles * 10) Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    showCompletion = false
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color.accentColor))
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

    // MARK: - Session Logic

    private func startSession() {
        currentCycle = 1
        BreatheAudioService.shared.speakIntro(cycles: selectedCycles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [self] in
            startPhase(.breatheIn)
            isRunning = true
        }
    }

    private func stopSession() {
        stopTimer()
        BreatheAudioService.shared.stopAll()
        phase = .idle
        countdown = 0
        isRunning = false
        currentCycle = 1
    }

    private func startPhase(_ newPhase: BreathingPhase) {
        phase = newPhase
        countdown = newPhase.duration
        BreatheAudioService.shared.speakPhase(
            newPhase.rawValue, cycle: currentCycle, totalCycles: selectedCycles
        )
        startTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in tick() }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard countdown > 1 else {
            advancePhase()
            return
        }
        countdown -= 1
    }

    private func advancePhase() {
        let next = phase.next

        if phase == .breatheOut {
            if currentCycle >= selectedCycles {
                completeSession()
                return
            }
            BreatheAudioService.shared.speakCycleTransition(
                currentCycle: currentCycle, totalCycles: selectedCycles
            )
            currentCycle += 1
        }

        startPhase(next)
    }

    private func completeSession() {
        stopTimer()
        isRunning = false
        BreatheAudioService.shared.speakCompletion(cycles: selectedCycles)

        let totalSeconds = selectedCycles * (4 + 7 + 8)
        Task {
            await store.logBreathingSession(
                userId: userId,
                cyclesCompleted: selectedCycles,
                durationSeconds: totalSeconds
            )
        }

        showCompletion = true
    }
}

#Preview {
    NavigationStack {
        BreatheSessionView()
            .environment(CalmCentreStore.shared)
    }
}
