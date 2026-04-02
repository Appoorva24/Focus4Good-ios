import SwiftUI

// MARK: - Muscle Step Data

private struct MuscleStep {
    let groupNumber: Int
    let name: String
    let icon: String
    let tenseInstruction: String
    let releaseNote: String
}

private let allSteps: [MuscleStep] = [
    .init(groupNumber: 1,  name: "Feet",            icon: "figure.walk",                       tenseInstruction: "Curl your toes downward tightly",                     releaseNote: "Feel the relaxation spread through your feet"),
    .init(groupNumber: 2,  name: "Calves",           icon: "figure.run",                        tenseInstruction: "Pull your toes toward your shins, tensing your calves", releaseNote: "Let the tension flow out of your calves"),
    .init(groupNumber: 3,  name: "Thighs",           icon: "figure.strengthtraining.traditional", tenseInstruction: "Squeeze your thigh muscles tightly together",          releaseNote: "Feel your thighs go heavy and relaxed"),
    .init(groupNumber: 4,  name: "Hips & Buttocks",  icon: "figure.cooldown",                   tenseInstruction: "Clench your gluteal muscles",                          releaseNote: "Let your hips sink and soften"),
    .init(groupNumber: 5,  name: "Abdomen",          icon: "figure.core.training",              tenseInstruction: "Suck your stomach in and tighten your core",            releaseNote: "Let your belly go completely soft"),
    .init(groupNumber: 6,  name: "Chest",            icon: "lungs.fill",                        tenseInstruction: "Take a deep breath and hold, tensing your chest",        releaseNote: "Exhale and feel your breathing slow naturally"),
    .init(groupNumber: 7,  name: "Hands & Forearms", icon: "hand.raised.fill",                  tenseInstruction: "Make tight fists with both hands",                      releaseNote: "Let your fingers go completely limp"),
    .init(groupNumber: 8,  name: "Upper Arms",       icon: "figure.arms.open",                  tenseInstruction: "Bend your elbows and flex your biceps hard",             releaseNote: "Let your arms fall heavy by your sides"),
    .init(groupNumber: 9,  name: "Shoulders",        icon: "figure.stand",                      tenseInstruction: "Shrug your shoulders up toward your ears",               releaseNote: "Let them drop completely"),
    .init(groupNumber: 10, name: "Neck",             icon: "person.crop.circle",                tenseInstruction: "Gently press the back of your head into the surface",    releaseNote: "Release and feel your neck lengthen"),
    .init(groupNumber: 11, name: "Forehead",         icon: "face.smiling",                      tenseInstruction: "Raise your eyebrows as high as possible",                releaseNote: "Let your forehead go smooth"),
    .init(groupNumber: 11, name: "Eyes",             icon: "eye.fill",                          tenseInstruction: "Squeeze your eyes shut tightly",                         releaseNote: "Let your eyelids rest gently"),
    .init(groupNumber: 11, name: "Jaw",              icon: "face.smiling",                      tenseInstruction: "Clench your teeth and tighten your jaw",                 releaseNote: "Let your mouth hang slightly open"),
]

// MARK: - Presets

private enum SessionPreset: CaseIterable {
    case quick, standard, full

    var label: String {
        switch self {
        case .quick:    "Quick"
        case .standard: "Standard"
        case .full:     "Full Body"
        }
    }

    var detail: String {
        switch self {
        case .quick:    "4 key areas"
        case .standard: "7 groups"
        case .full:     "All 11"
        }
    }

    var groups: Set<Int> {
        switch self {
        case .quick:    [5, 7, 9, 11]
        case .standard: [1, 3, 5, 7, 8, 9, 11]
        case .full:     Set(1...11)
        }
    }
}

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

    @State private var selectedGroups: Set<Int> = Set(1...11)
    @State private var stage: SessionStage = .idle
    @State private var countdown      = 0
    @State private var stepIndex      = 0
    @State private var endingIndex    = 0
    @State private var isRunning      = false
    @State private var showCompletion = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    private var userId: UUID {
        userStore.currentUser?.id ?? UUID()
    }

    private var activeSteps: [MuscleStep] {
        allSteps.filter { selectedGroups.contains($0.groupNumber) }
    }

    private var activeGroupsSorted: [Int] { selectedGroups.sorted() }

    private var currentStep: MuscleStep {
        activeSteps[min(stepIndex, max(activeSteps.count - 1, 0))]
    }

    private var currentEnding: EndingStep {
        EndingStep(rawValue: min(endingIndex, EndingStep.allCases.count - 1)) ?? .deepBreaths
    }

    private var activePreset: SessionPreset? {
        SessionPreset.allCases.first { $0.groups == selectedGroups }
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
            ToolbarItem(placement: .topBarTrailing) { groupMenu }
        }
        .onDisappear {
            stopTimer()
            JPMRAudioService.shared.stopAll()
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
                Text("Group \(groupIndex) of \(selectedGroups.count)")
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
                Text("\(selectedGroups.count) group\(selectedGroups.count == 1 ? "" : "s") selected")
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

    private var groupMenu: some View {
        Menu {
            ForEach(SessionPreset.allCases, id: \.label) { preset in
                Button {
                    selectedGroups = preset.groups
                } label: {
                    HStack {
                        Text("\(preset.label) — \(preset.detail)")
                        if activePreset == preset { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(selectedGroups.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Image(systemName: "figure.mind.and.body")
                    .font(.title3)
            }
            .foregroundStyle(Color.accentColor)
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
        .disabled(selectedGroups.isEmpty)
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

                Text("You completed \(selectedGroups.count) muscle group\(selectedGroups.count == 1 ? "" : "s") of progressive relaxation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 30 Focus Points")
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
        guard !selectedGroups.isEmpty else { return }
        stepIndex = 0
        endingIndex = 0
        elapsedSeconds = 0
        isRunning = true
        enterPreparation()
    }

    private func stopSession() {
        stopTimer()
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
        JPMRAudioService.shared.speakPreparation(groupCount: selectedGroups.count)
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
            advance()
            return
        }
        countdown -= 1
    }

    private func advance() {
        switch stage {
        case .preparation:
            stepIndex = 0
            enterTense()

        case .tensing:
            enterRest()

        case .resting:
            if stepIndex >= activeSteps.count - 1 {
                enterEnding()
            } else {
                stopTimer()
                let nextIndex = stepIndex + 1
                let nextStep = activeSteps[nextIndex]
                let groupIndex = (activeGroupsSorted.firstIndex(of: nextStep.groupNumber) ?? 0) + 1
                JPMRAudioService.shared.speakGroupTransition(
                    nextName: nextStep.name,
                    currentIndex: groupIndex,
                    totalGroups: selectedGroups.count
                )
                stepIndex = nextIndex
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                    enterTense()
                }
            }

        case .ending:
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

    private func completeSession() {
        stopTimer()
        isRunning = false
        stage = .complete

        JPMRAudioService.shared.speakCompletion(groupCount: selectedGroups.count)

        Task {
            await store.logJpmrSession(userId: userId, durationSeconds: elapsedSeconds)
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
