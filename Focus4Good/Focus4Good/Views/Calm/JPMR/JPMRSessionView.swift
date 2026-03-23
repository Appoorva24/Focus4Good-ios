//
//  JPMRSessionView.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

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
    .init(groupNumber: 1,  name: "Feet",
          icon: "figure.walk",
          tenseInstruction: "Curl your toes downward tightly",
          releaseNote: "Feel the relaxation spread through your feet"),
    .init(groupNumber: 2,  name: "Calves",
          icon: "figure.run",
          tenseInstruction: "Pull your toes toward your shins, tensing your calves",
          releaseNote: "Let the tension flow out of your calves"),
    .init(groupNumber: 3,  name: "Thighs",
          icon: "figure.strengthtraining.traditional",
          tenseInstruction: "Squeeze your thigh muscles tightly together",
          releaseNote: "Feel your thighs go heavy and relaxed"),
    .init(groupNumber: 4,  name: "Hips & Buttocks",
          icon: "figure.cooldown",
          tenseInstruction: "Clench your gluteal muscles",
          releaseNote: "Let your hips sink and soften"),
    .init(groupNumber: 5,  name: "Abdomen",
          icon: "figure.core.training",
          tenseInstruction: "Suck your stomach in and tighten your core",
          releaseNote: "Let your belly go completely soft"),
    .init(groupNumber: 6,  name: "Chest",
          icon: "lungs.fill",
          tenseInstruction: "Take a deep breath and hold, tensing your chest",
          releaseNote: "Exhale and feel your breathing slow naturally"),
    .init(groupNumber: 7,  name: "Hands & Forearms",
          icon: "hand.raised.fill",
          tenseInstruction: "Make tight fists with both hands",
          releaseNote: "Let your fingers go completely limp"),
    .init(groupNumber: 8,  name: "Upper Arms",
          icon: "figure.arms.open",
          tenseInstruction: "Bend your elbows and flex your biceps hard",
          releaseNote: "Let your arms fall heavy by your sides"),
    .init(groupNumber: 9,  name: "Shoulders",
          icon: "figure.stand",
          tenseInstruction: "Shrug your shoulders up toward your ears",
          releaseNote: "Let them drop completely"),
    .init(groupNumber: 10, name: "Neck",
          icon: "person.crop.circle",
          tenseInstruction: "Gently press the back of your head into the surface",
          releaseNote: "Release and feel your neck lengthen"),
    .init(groupNumber: 11, name: "Forehead",
          icon: "face.smiling",
          tenseInstruction: "Raise your eyebrows as high as possible",
          releaseNote: "Let your forehead go smooth"),
    .init(groupNumber: 11, name: "Eyes",
          icon: "eye.fill",
          tenseInstruction: "Squeeze your eyes shut tightly",
          releaseNote: "Let your eyelids rest gently"),
    .init(groupNumber: 11, name: "Jaw",
          icon: "face.smiling",
          tenseInstruction: "Clench your teeth and tighten your jaw",
          releaseNote: "Let your mouth hang slightly open"),
]

// MARK: - Group Metadata (for the selection menu)

private struct GroupMeta {
    let number: Int
    let name: String
    let icon: String
}

private let allGroupMetas: [GroupMeta] = [
    .init(number: 1,  name: "Feet",             icon: "figure.walk"),
    .init(number: 2,  name: "Calves",            icon: "figure.run"),
    .init(number: 3,  name: "Thighs",            icon: "figure.strengthtraining.traditional"),
    .init(number: 4,  name: "Hips & Buttocks",   icon: "figure.cooldown"),
    .init(number: 5,  name: "Abdomen",           icon: "figure.core.training"),
    .init(number: 6,  name: "Chest",             icon: "lungs.fill"),
    .init(number: 7,  name: "Hands & Forearms",  icon: "hand.raised.fill"),
    .init(number: 8,  name: "Upper Arms",        icon: "figure.arms.open"),
    .init(number: 9,  name: "Shoulders",         icon: "figure.stand"),
    .init(number: 10, name: "Neck",              icon: "person.crop.circle"),
    .init(number: 11, name: "Face",              icon: "face.smiling"),
]

// MARK: - Presets

private enum SessionPreset: CaseIterable {
    case quick, standard, full

    var label: String {
        switch self {
        case .quick:    return "Quick"
        case .standard: return "Standard"
        case .full:     return "Full Body"
        }
    }

    var detail: String {
        switch self {
        case .quick:    return "4 key areas"
        case .standard: return "7 groups"
        case .full:     return "All 11"
        }
    }

    var groups: Set<Int> {
        switch self {
        case .quick:    return [5, 7, 9, 11]          // Abdomen, Hands, Shoulders, Face
        case .standard: return [1, 3, 5, 7, 8, 9, 11] // common subset
        case .full:     return Set(1...11)
        }
    }
}

// MARK: - Session Stage

private enum SessionStage: Equatable {
    case idle
    case preparation
    case tensing
    case resting
    case ending
    case complete
}

// MARK: - Ending Step

private enum EndingStep: Int, CaseIterable {
    case deepBreaths = 0
    case bodyScan    = 1
    case wiggle      = 2
    case openEyes    = 3

    var title: String {
        switch self {
        case .deepBreaths: return "Deep Breaths"
        case .bodyScan:    return "Body Scan"
        case .wiggle:      return "Awaken"
        case .openEyes:    return "Return"
        }
    }

    var instruction: String {
        switch self {
        case .deepBreaths: return "Take 3 slow, deep breaths"
        case .bodyScan:    return "Mentally scan your body from head to toe\nNotice the relaxation"
        case .wiggle:      return "Gently wiggle your fingers and toes"
        case .openEyes:    return "Open your eyes slowly\nSit up gradually"
        }
    }

    var icon: String {
        switch self {
        case .deepBreaths: return "wind"
        case .bodyScan:    return "figure.mind.and.body"
        case .wiggle:      return "hand.raised.fingers.spread"
        case .openEyes:    return "eye"
        }
    }

    var duration: Int {
        switch self {
        case .deepBreaths: return 15
        case .bodyScan:    return 10
        case .wiggle:      return 5
        case .openEyes:    return 5
        }
    }
}

// MARK: - Timing Constants

private let accentOrange   = Color("CalmOrange")
private let tenseDuration  = 7
private let restDuration   = 20
private let prepDuration   = 20

// MARK: - JPMRSessionView

@available(iOS 17.0, *)
struct JPMRSessionView: View {

    private var store: CalmCentreStore { CalmCentreStore.shared }
    @Environment(\.dismiss) private var dismiss

    // Group selection
    @State private var selectedGroups: Set<Int> = Set(1...11)

    // Session state
    @State private var stage: SessionStage = .idle
    @State private var countdown       = 0
    @State private var stepIndex       = 0
    @State private var endingIndex     = 0
    @State private var isRunning       = false
    @State private var showCompletion  = false
    @State private var elapsedSeconds  = 0

    // Timer
    @State private var timer: Timer?
    private let userId = UUID()

    // MARK: Active steps (filtered by selection)

    private var activeSteps: [MuscleStep] {
        allSteps.filter { selectedGroups.contains($0.groupNumber) }
    }

    private var activeGroupsSorted: [Int] {
        selectedGroups.sorted()
    }

    private var currentStep: MuscleStep {
        activeSteps[min(stepIndex, max(activeSteps.count - 1, 0))]
    }

    private var currentEnding: EndingStep {
        EndingStep(rawValue: min(endingIndex, EndingStep.allCases.count - 1)) ?? .deepBreaths
    }

    // Which preset is currently active (if any)
    private var activePreset: SessionPreset? {
        SessionPreset.allCases.first { $0.groups == selectedGroups }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                circleArea
                infoArea
                    .padding(.top, 28)
                Spacer()
                progressArea
                    .padding(.bottom, 24)
                actionButton
                    .padding(.bottom, 48)
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
            ToolbarItem(placement: .topBarTrailing) {
                groupMenu
            }
        }
        .onDisappear { stopTimer() }
    }
}

// MARK: - Display Helpers

@available(iOS 17.0, *)
private extension JPMRSessionView {

    var displayIcon: String {
        switch stage {
        case .idle:        return "figure.mind.and.body"
        case .preparation: return "wind"
        case .tensing:     return currentStep.icon
        case .resting:     return currentStep.icon
        case .ending:      return currentEnding.icon
        case .complete:    return "checkmark.seal.fill"
        }
    }

    var displayTitle: String {
        switch stage {
        case .idle:        return "Ready"
        case .preparation: return "Settle In"
        case .tensing:     return currentStep.name
        case .resting:     return currentStep.name
        case .ending:      return currentEnding.title
        case .complete:    return "Complete"
        }
    }

    var displayPhaseLabel: String {
        switch stage {
        case .idle:        return "Press Start to begin"
        case .preparation: return "Close your eyes and breathe deeply"
        case .tensing:     return "Inhale & Tense"
        case .resting:     return "Release & Rest"
        case .ending:      return currentEnding.instruction
        case .complete:    return ""
        }
    }

    var displayDetail: String {
        switch stage {
        case .tensing: return currentStep.tenseInstruction
        case .resting: return currentStep.releaseNote
        default:       return ""
        }
    }

    var circleScale: CGFloat {
        switch stage {
        case .tensing: return 1.2
        case .resting: return 0.85
        default:       return 1.0
        }
    }

    var circleFillOpacity: Double {
        switch stage {
        case .tensing: return 0.28
        case .resting: return 0.10
        default:       return 0.18
        }
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private extension JPMRSessionView {

    // MARK: Circle

    var circleArea: some View {
        ZStack {
            Circle()
                .stroke(accentOrange.opacity(0.15), lineWidth: 8)
                .frame(width: 220, height: 220)

            Circle()
                .fill(accentOrange.opacity(circleFillOpacity))
                .frame(width: 180, height: 180)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: Double(max(countdown, 1))), value: stage)

            VStack(spacing: 10) {
                Image(systemName: displayIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(accentOrange)
                    .contentTransition(.symbolEffect(.replace))

                Text("\(countdown)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(stage == .tensing ? accentOrange : .secondary)
                    .contentTransition(.numericText())
                    .opacity(isRunning ? 1 : 0)
            }
        }
        .frame(width: 240, height: 240)
    }

    // MARK: Info

    var infoArea: some View {
        VStack(spacing: 8) {
            Text(displayTitle)
                .font(.title3)
                .fontWeight(.bold)

            Text(displayPhaseLabel)
                .font(.headline)
                .foregroundStyle(accentOrange)
                .multilineTextAlignment(.center)

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

    // MARK: Progress

    var progressArea: some View {
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

    func groupDotColor(for group: Int) -> Color {
        guard isRunning || stage == .ending || stage == .complete else {
            return Color(.systemGray4)
        }

        if stage == .ending || stage == .complete {
            return accentOrange
        }

        let currentGroup = currentStep.groupNumber
        if group < currentGroup {
            return accentOrange
        } else if group == currentGroup {
            return accentOrange.opacity(0.5)
        }
        return Color(.systemGray4)
    }

    // MARK: Group Selection Menu

    var groupMenu: some View {
        Menu {
            // Presets section
            Section("Presets") {
                ForEach(SessionPreset.allCases, id: \.label) { preset in
                    Button {
                        selectedGroups = preset.groups
                    } label: {
                        HStack {
                            Text("\(preset.label) — \(preset.detail)")
                            if activePreset == preset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            // Individual group toggles
            Section("Muscle Groups") {
                ForEach(allGroupMetas, id: \.number) { meta in
                    Button {
                        toggleGroup(meta.number)
                    } label: {
                        HStack {
                            Image(systemName: meta.icon)
                            Text(meta.name)
                            if selectedGroups.contains(meta.number) {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
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
            .foregroundStyle(accentOrange)
        }
        .disabled(isRunning)
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
        .disabled(selectedGroups.isEmpty)
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

                Text("You completed \(selectedGroups.count) muscle group\(selectedGroups.count == 1 ? "" : "s") of progressive relaxation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 30 Focus Points")
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
private extension JPMRSessionView {

    // MARK: Group Toggle

    func toggleGroup(_ group: Int) {
        if selectedGroups.contains(group) {
            if selectedGroups.count > 1 {
                selectedGroups.remove(group)
            }
        } else {
            selectedGroups.insert(group)
        }
    }

    // MARK: Start / Stop

    func startSession() {
        guard !selectedGroups.isEmpty else { return }
        stepIndex = 0
        endingIndex = 0
        elapsedSeconds = 0
        isRunning = true
        enterPreparation()
    }

    func stopSession() {
        stopTimer()
        stage = .idle
        countdown = 0
        isRunning = false
        stepIndex = 0
        endingIndex = 0
        elapsedSeconds = 0
    }

    // MARK: Phase Entries

    func enterPreparation() {
        stage = .preparation
        countdown = prepDuration
        startTimer()
    }

    func enterTense() {
        stage = .tensing
        countdown = tenseDuration
        startTimer()
    }

    func enterRest() {
        stage = .resting
        countdown = restDuration
        startTimer()
    }

    func enterEnding() {
        endingIndex = 0
        enterEndingStep()
    }

    func enterEndingStep() {
        stage = .ending
        countdown = currentEnding.duration
        startTimer()
    }

    // MARK: Timer

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
        elapsedSeconds += 1

        guard countdown > 1 else {
            advance()
            return
        }
        countdown -= 1
    }

    // MARK: Advance

    func advance() {
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
                stepIndex += 1
                enterTense()
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

    // MARK: Complete

    func completeSession() {
        stopTimer()
        isRunning = false
        stage = .complete

        Task {
            await store.logJpmrSession(
                userId: userId,
                durationSeconds: elapsedSeconds
            )
        }

        showCompletion = true
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        JPMRSessionView()
    }
}
