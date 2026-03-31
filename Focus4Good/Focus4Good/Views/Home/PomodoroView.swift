import SwiftUI

struct PomodoroView: View {
    let task: UserTask
    @Environment(TaskStore.self)     private var taskStore
    @Environment(UserStore.self)     private var userStore
    @Environment(ProgressStore.self) private var progressStore
    @Environment(\.dismiss)          private var dismiss

    @State private var timeRemaining: Int
    @State private var isBreak = false
    @State private var currentSession = 1
    @State private var distractedCount = 0
    @State private var showEndSessionAlert = false
    @State private var showOverwhelmedSheet = false
    @State private var showBreakScreen = false
    @State private var sessionComplete = false
    @State private var timer: Timer?
    @State private var totalFocusMinutes = 0
    @State private var breathePhase = false

    private let totalSessions: Int
    private let sessionDuration = 25 * 60
    private let breakDuration = 5 * 60

    init(task: UserTask) {
        self.task = task
        let duration = task.estimatedDuration ?? 25
        self.totalSessions = max(1, Int(ceil(Double(duration) / 25.0)))
        self._timeRemaining = State(initialValue: 25 * 60)
    }

    private var progress: Double {
        let total = isBreak ? Double(breakDuration) : Double(sessionDuration)
        return 1.0 - (Double(timeRemaining) / total)
    }

    private var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    var body: some View {
        Group {
            if sessionComplete {
                SessionCompleteView(
                    totalSessions: totalSessions,
                    totalFocusMinutes: totalFocusMinutes,
                    distractedCount: distractedCount,
                    onDismiss: { dismiss() }
                )
            } else if showBreakScreen {
                breakView
            } else {
                timerView
            }
        }
        .onDisappear { timer?.invalidate() }
        .sheet(isPresented: $showOverwhelmedSheet) {
            OverwhelmedSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Leave Session Early?", isPresented: $showEndSessionAlert) {
            Button("Keep Going", role: .cancel) {}
            Button("End Anyway", role: .destructive) { dismiss() }
        } message: {
            Text("If you stop now, you won't earn focus points and your classroom won't grow today. Stay a little longer and help the student move forward.")
        }
    }

    // MARK: - Timer View
    private var timerView: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                modeBadge.padding(.top, 60)

                Text(task.title)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                Spacer()
                timerRing
                Spacer()

                sessionInfo.padding(.bottom, 40)

                distractedButton.padding(.horizontal, 40).padding(.bottom, 16)
                endSessionButton.padding(.bottom, 48)
            }
        }
        .onAppear { startTimer() }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Break View (Figma style)
    private var breakView: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Breathing circle
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFF3E8"))
                        .frame(width: 220, height: 220)
                        .scaleEffect(breathePhase ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathePhase)

                    Circle()
                        .stroke(AppTheme.orange.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 220, height: 220)

                    VStack(spacing: 6) {
                        Text(breathePhase ? "EXHALE" : "INHALE")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundStyle(AppTheme.orange)
                            .kerning(3)
                        Text("~")
                            .font(.title2)
                            .foregroundStyle(AppTheme.orange.opacity(0.6))
                    }
                }
                .onAppear { breathePhase = true }

                Spacer()

                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.orange)

                Text("Relaxation Break")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, 4)

                Spacer()

                Button { skipBreak() } label: {
                    HStack(spacing: 8) {
                        Text("Skip and start new session")
                            .font(.headline)
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(AppTheme.orange.opacity(0.2)))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

                Button { dismiss() } label: {
                    Text("End Session")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear { startBreakTimer() }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews
    private var modeBadge: some View {
        Capsule()
            .fill(AppTheme.orange.opacity(0.15))
            .frame(width: 140, height: 32)
            .overlay(
                Text("• DEEP FOCUS")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.orange)
            )
    }

    private var timerRing: some View {
        ZStack {
            Circle().stroke(AppTheme.orange.opacity(0.15), lineWidth: 16).frame(width: 260, height: 260)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.orange, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            Text(timeString)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var sessionInfo: some View {
        VStack(spacing: 12) {
            Text("SESSION \(currentSession) OF \(totalSessions)")
                .font(.caption.bold()).foregroundStyle(AppTheme.textSecondary).kerning(1.2)
            HStack(spacing: 6) {
                ForEach(0..<totalSessions, id: \.self) { index in
                    Circle()
                        .fill(index < currentSession ? AppTheme.orange : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var distractedButton: some View {
        Button {
            distractedCount += 1
            if distractedCount >= 5 { showOverwhelmedSheet = true }
        } label: {
            Text("Distracted").font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Capsule().fill(AppTheme.orange))
        }
    }

    private var endSessionButton: some View {
        Button { showEndSessionAlert = true } label: {
            Text("End Session").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Timer Logic
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard timeRemaining > 0 else { handleSessionEnd(); return }
            timeRemaining -= 1
        }
    }

    private func startBreakTimer() {
        timeRemaining = breakDuration
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard timeRemaining > 0 else { handleBreakEnd(); return }
            timeRemaining -= 1
        }
    }

    private func handleSessionEnd() {
        timer?.invalidate()
        totalFocusMinutes += 25

        if currentSession >= totalSessions {
            // All sessions done — award points and record progress
            let points = max(0, (totalSessions * 25 * 2) - (distractedCount * 5))
            guard let userId = userStore.currentUser?.id else {
                sessionComplete = true
                return
            }
            Task {
                // Mark task complete (also calls ProgressStore.incrementTasksCompleted)
                await taskStore.toggleCompletion(for: task)
                // Update focus points on the User object
                await userStore.updateFocusPoints(by: points)
                // Record focus time and points in ProgressStore
                await progressStore.addFocusTime(minutes: totalFocusMinutes, userId: userId)
                await progressStore.addPointsEarned(points: points, userId: userId)
            }
            sessionComplete = true
        } else {
            showBreakScreen = true
        }
    }

    private func handleBreakEnd() {
        timer?.invalidate()
        currentSession += 1
        timeRemaining = sessionDuration
        showBreakScreen = false
        startTimer()
    }

    private func skipBreak() {
        timer?.invalidate()
        currentSession += 1
        timeRemaining = sessionDuration
        showBreakScreen = false
        breathePhase = false
        startTimer()
    }
}

// MARK: - Overwhelmed Sheet
struct OverwhelmedSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 52)).foregroundStyle(AppTheme.orange).padding(.top, 32)

            VStack(spacing: 8) {
                Text("Feeling a little overwhelmed?").font(.title3.bold()).multilineTextAlignment(.center)
                Text("You seem quite distracted right now. Would you like to take a short meditation break and reset your focus?")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Text("Go to Calm Centre")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Capsule().fill(Color(.systemGray3)))
                    .padding(.horizontal, 32)

                Button { dismiss() } label: {
                    Text("Stay in session").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Session Complete
struct SessionCompleteView: View {
    let totalSessions: Int
    let totalFocusMinutes: Int
    let distractedCount: Int
    let onDismiss: () -> Void

    private var pointsEarned: Int {
        max(0, (totalSessions * 25 * 2) - (distractedCount * 5))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                VStack(spacing: 8) {
                    Text("Well Done").font(.largeTitle.bold()).foregroundStyle(AppTheme.textPrimary)
                    Text("Focus session complete").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 160)
                        .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20)
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill").font(.system(size: 32)).foregroundStyle(.white.opacity(0.9))
                        Text("\(totalSessions) Session\(totalSessions > 1 ? "s" : "")").font(.headline.bold()).foregroundStyle(.white)
                        Text("COMPLETED").font(.caption.bold()).foregroundStyle(.white.opacity(0.85)).kerning(1.2)
                    }
                }

                HStack(spacing: 0) {
                    statItem(label: "TOTAL FOCUS", value: "\(totalFocusMinutes)m")
                    Divider().frame(height: 40)
                    statItem(label: "DISTRACTIONS", value: "\(distractedCount)")
                }
                .padding(.vertical, 20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal, 40)

                Text("+ \(pointsEarned) Focus Points").font(.title2.bold()).foregroundStyle(AppTheme.orange)

                Spacer()

                Button(action: onDismiss) {
                    Text("Go to Planner").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Capsule().fill(AppTheme.orange))
                }
                .padding(.horizontal, 32).padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary).kerning(0.5)
            Text(value).font(.title3.bold()).foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
