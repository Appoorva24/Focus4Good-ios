import SwiftUI

// MARK: - Breathing Phase
/// Defines the different stages of a breathing cycle (Inhale, Hold, Exhale).
private enum BreathingPhase: String {
    case inhale  = "Breathe In"
    case hold    = "Hold"
    case exhale  = "Breathe Out"
    case idle    = "Get Ready"

    var duration: Int {
        switch self {
        case .inhale:  return 4
        case .hold:    return 7
        case .exhale:  return 8
        case .idle:    return 0
        }
    }

    var next: BreathingPhase {
        switch self {
        case .idle:    return .inhale
        case .inhale:  return .hold
        case .hold:    return .exhale
        case .exhale:  return .inhale
        }
    }

    var circleScale: CGFloat {
        switch self {
        case .inhale, .hold: return 1.2
        case .exhale, .idle: return 0.85
        }
    }
}

struct BreatheSessionView: View {
    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var isRunning = false
    @State private var isCompleted = false
    @State private var showExitAlert = false
    @State private var selectedCycles = 4
    @State private var currentCycle = 1
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var phase: BreathingPhase = .idle

    private let audio = BreatheAudioService.shared

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

            if isCompleted {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }

            if showExitAlert {
                exitOverlay
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCompleted)
        .navigationTitle("Breathe")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if isRunning {
                        showExitAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .topBarTrailing) { cycleMenu }
        }
        .onDisappear {
            stopSession()
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
                .animation(.easeInOut(duration: Double(max(phase.duration, 1))), value: phase)

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
            ForEach(1...8, id: \.self) { count in
                Button {
                    if !isRunning { selectedCycles = count }
                } label: {
                    HStack {
                        Text("\(count) Cycle\(count == 1 ? "" : "s")")
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
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Well Done!")
                    .font(.title2.bold())

                Text("You completed \(selectedCycles) rounds of deep breathing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ \(selectedCycles * 10) Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    isCompleted = false
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 40)
        }
    }

    private var exitOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("End Session?")
                        .font(.title3.bold())
                    Text("Your points won't be saved.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    Button("Keep Going") { showExitAlert = false }
                        .buttonStyle(.bordered)
                    Button("Yes, Exit") {
                        stopSession()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .padding(40)
        }
    }

    // MARK: - Logic

    private func startSession() {
        isRunning = true
        isCompleted = false
        currentCycle = 1
        phase = .idle
        audio.speakIntro(cycles: selectedCycles)
        audio.onSpeechFinished = {
            audio.onSpeechFinished = nil
            startNewPhase(.inhale)
        }
    }

    private func stopSession() {
        timer?.invalidate()
        timer = nil
        audio.stopAll()
        isRunning = false
        phase = .idle
    }

    private func startNewPhase(_ newPhase: BreathingPhase) {
        phase = newPhase
        countdown = newPhase.duration
        audio.speakPhase(newPhase.rawValue, cycle: currentCycle, totalCycles: selectedCycles)
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                if audio.isSpeaking { return }
                advancePhase()
            }
        }
    }

    private func advancePhase() {
        if phase == .exhale {
            if currentCycle < selectedCycles {
                currentCycle += 1
                audio.speakCycleTransition(currentCycle: currentCycle, totalCycles: selectedCycles)
                timer?.invalidate()
                audio.onSpeechFinished = {
                    audio.onSpeechFinished = nil
                    startNewPhase(.inhale)
                }
            } else {
                finishSession()
            }
        } else {
            startNewPhase(phase.next)
        }
    }

    private func finishSession() {
        stopSession()
        isCompleted = true
        audio.speakCompletion(cycles: selectedCycles)
        if let userId = userStore.currentUser?.id {
            Task {
                await store.logBreathingSession(userId: userId, cyclesCompleted: selectedCycles, durationSeconds: selectedCycles * 19)
            }
        }
    }
}
