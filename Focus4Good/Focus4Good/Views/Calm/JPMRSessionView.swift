import SwiftUI

// MARK: - Muscle Step Data

private struct MuscleStep {
    let groupNumber: Int
    let name: String
    let icon: String
    let tenseInstruction: String
    let releaseNote: String
}

/// The list of the 4 primary muscle groups for a focused JPMR session.
private let allSteps: [MuscleStep] = [
    .init(groupNumber: 1, name: "Feet & Legs", icon: "figure.walk", tenseInstruction: "Curl your toes downward and tense your legs", releaseNote: "Feel the relaxation spread through your lower body"),
    .init(groupNumber: 2, name: "Abdomen & Core", icon: "figure.core.training", tenseInstruction: "Suck your stomach in and tighten your core", releaseNote: "Let your belly go completely soft"),
    .init(groupNumber: 3, name: "Hands & Arms", icon: "hand.raised.fill", tenseInstruction: "Make tight fists and flex your arms", releaseNote: "Let your fingers and arms go completely limp"),
    .init(groupNumber: 4, name: "Shoulders & Neck", icon: "figure.stand", tenseInstruction: "Shrug your shoulders up toward your ears", releaseNote: "Let them drop completely and feel the tension leave your neck"),
]

// MARK: - Session Stage

private enum SessionStage: Equatable {
    case idle, preparation, tensing, resting, ending, complete
}

// MARK: - Ending Step

private enum EndingStep: Int, CaseIterable {
    case deepBreaths = 0, bodyScan = 1, wiggle = 2, openEyes = 3

    var title: String {
        switch self {
        case .deepBreaths: "Deep Breaths"
        case .bodyScan:    "Body Scan"
        case .wiggle:      "Awaken"
        case .openEyes:    "Return"
        }
    }

    var instruction: String {
        switch self {
        case .deepBreaths: "Take 3 slow, deep breaths"
        case .bodyScan:    "Mentally scan your body from head to toe\nNotice the relaxation"
        case .wiggle:      "Gently wiggle your fingers and toes"
        case .openEyes:    "Open your eyes slowly\nSit up gradually"
        }
    }

    var icon: String {
        switch self {
        case .deepBreaths: "wind"
        case .bodyScan:    "figure.mind.and.body"
        case .wiggle:      "hand.raised.fingers.spread"
        case .openEyes:    "eye"
        }
    }

    var duration: Int {
        switch self {
        case .deepBreaths: 15
        case .bodyScan:    10
        case .wiggle:      5
        case .openEyes:    5
        }
    }
}

// MARK: - Timing Constants

private let tenseDuration = 7
private let restDuration  = 20
private let prepDuration  = 20

// MARK: - JPMRSessionView

struct JPMRSessionView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    // Link to the external guided video
    private let youtubeVideoURL = "https://youtu.be/ihO02wUzgkc?si=sUTR2YkGJeIRck8i"

    // MARK: - State
    @State private var stage: SessionStage = .idle
    @State private var countdown      = 0
    @State private var stepIndex      = 0
    @State private var endingIndex    = 0
    @State private var isRunning      = false
    @State private var showCompletion = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    // Tracks if the user is watching the external video
    @State private var pendingVideoCompletion = false
    @State private var showVideoCompletionAlert = false
    @State private var isVideoCompletion = false

    private var userId: UUID? {
        userStore.currentUser?.id
    }

    // Now simply uses the 4 focused steps
    private var activeSteps: [MuscleStep] { allSteps }

    private var activeGroupsSorted: [Int] { allSteps.map { $0.groupNumber } }

    private var currentStep: MuscleStep {
        activeSteps[min(stepIndex, max(activeSteps.count - 1, 0))]
    }

    private var currentEnding: EndingStep {
        EndingStep(rawValue: min(endingIndex, EndingStep.allCases.count - 1)) ?? .deepBreaths
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                circleArea
                infoArea.padding(.top, 28)
                Spacer()
                progressArea.padding(.bottom, 24)
                actionButton.padding(.bottom, 48)
            }

            if showCompletion {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        .navigationTitle("Unwind Body")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { sessionMenu }
        }
        .onDisappear {
            stopTimer()
            JPMRAudioService.shared.onSpeechFinished = nil
            JPMRAudioService.shared.stopAll()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && pendingVideoCompletion {
                pendingVideoCompletion = false
                showVideoCompletionAlert = true
            }
        }
        .overlay {
            if showVideoCompletionAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showVideoCompletionAlert = false
                        }

                    VStack(spacing: 20) {
                        Text("Video Session Complete?")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)

                        Text("Did you complete the full JPMR guided video?")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.7))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button {
                                showVideoCompletionAlert = false
                            } label: {
                                Text("Not yet")
                                    .font(.headline)
                                    .foregroundStyle(.black.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Capsule().fill(Color(.systemGray5)))
                            }

                            Button {
                                showVideoCompletionAlert = false
                                completeVideoSession()
                            } label: {
                                Text("Yes, I did!")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Capsule().fill(Color.accentColor))
                            }
                        }
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 36)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: showVideoCompletionAlert)
            }
        }
    }

    // MARK: - Display Helpers

    private var displayIcon: String {
        switch stage {
        case .idle:        "figure.mind.and.body"
        case .preparation: "wind"
        case .tensing:     currentStep.icon
        case .resting:     currentStep.icon
        case .ending:      currentEnding.icon
        case .complete:    "checkmark.seal.fill"
        }
    }

    private var displayTitle: String {
        switch stage {
        case .idle:        "Ready"
        case .preparation: "Settle In"
        case .tensing:     currentStep.name
        case .resting:     currentStep.name
        case .ending:      currentEnding.title
        case .complete:    "Complete"
        }
    }

    private var displayPhaseLabel: String {
        switch stage {
        case .idle:        "Press Start to begin"
        case .preparation: "Close your eyes and breathe deeply"
        case .tensing:     "Inhale & Tense"
        case .resting:     "Release & Rest"
        case .ending:      currentEnding.instruction
        case .complete:    ""
        }
    }

    private var displayDetail: String {
        switch stage {
        case .tensing: currentStep.tenseInstruction
        case .resting: currentStep.releaseNote
        default:       ""
        }
    }

    private var circleScale: CGFloat {
        switch stage {
        case .tensing: 1.2
        case .resting: 0.85
        default:       1.0
        }
    }

    private var circleFillOpacity: Double {
        switch stage {
        case .tensing: 0.28
        case .resting: 0.10
        default:       0.18
        }
    }

    // MARK: - Subviews

    private var circleArea: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 8)
                .frame(width: 220, height: 220)

            Circle()
                .fill(Color.accentColor.opacity(circleFillOpacity))
                .frame(width: 180, height: 180)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: Double(max(countdown, 1))), value: stage)

            VStack(spacing: 10) {
                Image(systemName: displayIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.symbolEffect(.replace))

                Text("\(countdown)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(stage == .tensing ? Color.accentColor : .secondary)
                    .contentTransition(.numericText())
                    .opacity(isRunning ? 1 : 0)
            }
        }
        .frame(width: 240, height: 240)
    }

    private var infoArea: some View {
        VStack(spacing: 8) {
            Text(displayTitle)
                .font(.title3)
                .fontWeight(.bold)

            Text(displayPhaseLabel)
                .font(.headline)
                .foregroundStyle(Color.accentColor)

            Text(displayDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(displayDetail.isEmpty ? 0 : 1)
                .frame(minHeight: 20)
        }
        .animation(.easeInOut(duration: 0.3), value: stage)
        .animation(.easeInOut(duration: 0.3), value: stepIndex)
        .padding(.horizontal, 32)
    }

    private var progressArea: some View {
        VStack(spacing: 12) {
            if stage == .tensing || stage == .resting {
                let groupIndex = (activeGroupsSorted.firstIndex(of: currentStep.groupNumber) ?? 0) + 1
                Text("Group \(groupIndex) of \(allSteps.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else if stage == .preparation {
                Text("Preparing…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if stage == .ending {
                Text("Closing…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(allSteps.count) Relaxation steps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 5) {
                ForEach(activeGroupsSorted, id: \.self) { group in
                    Circle()
                        .fill(groupDotColor(for: group))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(height: 44)
    }

    private func groupDotColor(for group: Int) -> Color {
        guard isRunning || stage == .ending || stage == .complete else {
            return Color(.systemGray4)
        }
        if stage == .ending || stage == .complete { return .accentColor }

        let currentGroup = currentStep.groupNumber
        if group < currentGroup { return .accentColor }
        if group == currentGroup { return Color.accentColor.opacity(0.5) }
        return Color(.systemGray4)
    }

    /// The menu button in the top bar
    private var sessionMenu: some View {
        Menu {
            Button {
                // Already using 4 groups, but keeping the button for UI consistency
            } label: {
                HStack {
                    Text("4 Key Areas")
                    Image(systemName: "checkmark")
                }
            }

            Button {
                pendingVideoCompletion = true
                if let url = URL(string: youtubeVideoURL) {
                    openURL(url)
                }
            } label: {
                HStack {
                    Text("Video Illustration")
                    Image(systemName: "arrow.up.right")
                }
            }
        } label: {
            Image(systemName: "figure.mind.and.body")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
        }
    }

    /// The start/stop toggle button
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

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showCompletion = false
                    isVideoCompletion = false
                    dismiss()
                }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Well Done!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(isVideoCompletion
                     ? "You completed the full JPMR guided video session"
                     : "You completed the 4 primary groups of progressive relaxation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(isVideoCompletion ? "+ 50 Focus Points" : "+ 30 Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    showCompletion = false
                    isVideoCompletion = false
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
        guard !allSteps.isEmpty else { return }
        stepIndex = 0
        endingIndex = 0
        elapsedSeconds = 0
        isRunning = true
        enterPreparation()
    }

    private func stopSession() {
        stopTimer()
        JPMRAudioService.shared.onSpeechFinished = nil
        JPMRAudioService.shared.stopAll()
        stage = .idle
        countdown = 0
        isRunning = false
        stepIndex = 0
        endingIndex = 0
        elapsedSeconds = 0
    }

    private func enterPreparation() {
        stage = .preparation
        countdown = prepDuration
        JPMRAudioService.shared.speakPreparation(groupCount: allSteps.count)
        startTimer()
    }

    private func enterTense() {
        stage = .tensing
        countdown = tenseDuration
        JPMRAudioService.shared.speakTense(muscleName: currentStep.name, instruction: currentStep.tenseInstruction)
        startTimer()
    }

    private func enterRest() {
        stage = .resting
        countdown = restDuration
        JPMRAudioService.shared.speakRest(muscleName: currentStep.name, releaseNote: currentStep.releaseNote)
        startTimer()
    }

    private func enterEnding() {
        endingIndex = 0
        enterEndingStep()
    }

    private func enterEndingStep() {
        stage = .ending
        countdown = currentEnding.duration
        JPMRAudioService.shared.speakEndingStep(title: currentEnding.title, instruction: currentEnding.instruction)
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
        elapsedSeconds += 1
        guard countdown > 1 else {
            // If the AI is still speaking, give it extra time to finish the sentence
            if JPMRAudioService.shared.isSpeaking {
                countdown = 2
                return
            }
            advance()
            return
        }
        countdown -= 1
    }

    /// Moves the session to the next stage (e.g. from Tense to Rest)
    private func advance() {
        switch stage {
        case .preparation:
            stepIndex = 0
            enterTense()

        case .tensing:
            enterRest()

        case .resting:
            // If we finished the last group, move to the ending breaths/scan
            if stepIndex >= activeSteps.count - 1 {
                enterEnding()
            } else {
                // Otherwise, transition to the next muscle group
                stopTimer()
                let nextIndex = stepIndex + 1
                let nextStep = activeSteps[nextIndex]
                
                JPMRAudioService.shared.speakGroupTransition(
                    nextName: nextStep.name,
                    currentIndex: nextIndex + 1,
                    totalGroups: allSteps.count
                )
                
                stepIndex = nextIndex
                // Wait for the AI to finish the transition before starting the 'Tense' phase
                JPMRAudioService.shared.onSpeechFinished = { [self] in
                    JPMRAudioService.shared.onSpeechFinished = nil
                    enterTense()
                }
            }

        case .ending:
            // If we finished all ending steps, complete the session
            if endingIndex >= EndingStep.allCases.count - 1 {
                completeSession()
            } else {
                endingIndex += 1
                enterEndingStep()
            }

        default:
            break
        }
    }

    /// Finalizes the session and speaks the completion message.
    private func completeSession() {
        stopTimer()
        isRunning = false
        stage = .complete

        JPMRAudioService.shared.speakCompletion(groupCount: allSteps.count)

        Task {
            guard let uid = userId else { return }
            await store.logJpmrSession(userId: uid, durationSeconds: elapsedSeconds)
        }

        showCompletion = true
    }

    private func completeVideoSession() {
        isVideoCompletion = true

        Task {
            guard let uid = userId else { return }
            await store.logJpmrSession(userId: uid, durationSeconds: 900, pointsOverride: 50)
        }

        showCompletion = true
    }
}

#Preview {
    NavigationStack {
        JPMRSessionView()
            .environment(CalmCentreStore.shared)
            .environment(UserStore.shared)
    }
}
