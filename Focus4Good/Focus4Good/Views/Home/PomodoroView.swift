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
    @State private var showPomodoroCompletePopup = false
    @State private var timer: Timer?
    @State private var totalFocusMinutes = 0
    @State private var breathePhase = false

    private let totalSessions: Int
    private let sessionDuration = 25 * 60
    private let breakDuration = 5 * 60
    private let pointsPerSession = 20
    private let pointsOnCompletion = 50

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
        ZStack {
            Group {
                if sessionComplete {
                    SessionCompleteView(
                        totalSessions: totalSessions,
                        totalFocusMinutes: totalFocusMinutes,
                        distractedCount: distractedCount,
                        pointsEarned: pointsOnCompletion,
                        onDismiss: { dismiss() }
                    )
                } else if showBreakScreen {
                    breakView
                } else {
                    timerView
                }
            }

            // Pomodoro session complete popup overlay
            if showPomodoroCompletePopup {
                PomodoroSessionPopup(
                    sessionNumber: currentSession,
                    totalSessions: totalSessions,
                    pointsEarned: pointsPerSession,
                    onContinue: {
                        showPomodoroCompletePopup = false
                        showBreakScreen = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPomodoroCompletePopup)
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
            Text("If you stop now, you won't earn focus points. Stay a little longer and stay focused.")
        }
    }

    // MARK: - Timer View (Dark Focus Mode)
    private var timerView: some View {
        ZStack {
            // Dark moody gradient background
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1E1B2E"), Color(hex: "1C1917")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle radial glow behind timer
            RadialGradient(
                colors: [AppTheme.orange.opacity(0.06), Color.clear],
                center: .center,
                startRadius: 80,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                modeBadge.padding(.top, 60)

                Text(task.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
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

    // MARK: - Break View
    private var breakView: some View {
        ZStack {
            // Calming break gradient
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1A1525"), Color(hex: "1C1917")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Breathing circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(AppTheme.sage.opacity(0.06))
                        .frame(width: 260, height: 260)
                        .scaleEffect(breathePhase ? 1.15 : 0.95)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: breathePhase)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.sage.opacity(0.12), AppTheme.sage.opacity(0.03)],
                                center: .center,
                                startRadius: 40,
                                endRadius: 110
                            )
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(breathePhase ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: breathePhase)

                    Circle()
                        .stroke(AppTheme.sage.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 220, height: 220)

                    VStack(spacing: 6) {
                        Text(breathePhase ? "EXHALE" : "INHALE")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundStyle(AppTheme.sage)
                            .kerning(3)
                        Text("~")
                            .font(.title2)
                            .foregroundStyle(AppTheme.sage.opacity(0.6))
                    }
                }
                .onAppear { breathePhase = true }

                Spacer()

                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.sage)

                Text("Relaxation Break")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.top, 4)

                Spacer()

                Button { skipBreak() } label: {
                    HStack(spacing: 8) {
                        Text("Skip and start new session")
                            .font(.headline)
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

                Button { dismiss() } label: {
                    Text("End Session")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear { startBreakTimer() }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews
    private var modeBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.orange)
                .frame(width: 6, height: 6)
            Text("DEEP FOCUS")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.orange)
                .kerning(1.2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(AppTheme.orange.opacity(0.12)))
    }

    private var timerRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 16)
                .frame(width: 260, height: 260)

            // Progress ring — multi-color gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppTheme.timerRingGradient,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Glowing dot at the end
            Circle()
                .fill(AppTheme.orange)
                .frame(width: 12, height: 12)
                .shadow(color: AppTheme.orange.opacity(0.6), radius: 8)
                .offset(y: -130)
                .rotationEffect(.degrees(360 * progress - 90))
                .animation(.linear(duration: 1), value: progress)

            // Center time
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .textCase(.uppercase)
                    .kerning(1)
            }
        }
    }

    private var sessionInfo: some View {
        VStack(spacing: 12) {
            Text("SESSION \(currentSession) OF \(totalSessions)")
                .font(.caption.bold()).foregroundStyle(Color.white.opacity(0.4)).kerning(1.2)
            HStack(spacing: 6) {
                ForEach(0..<totalSessions, id: \.self) { index in
                    Circle()
                        .fill(index < currentSession ? AppTheme.orange : Color.white.opacity(0.15))
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
            Text("Distracted")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Capsule().fill(AppTheme.buttonGradient))
                .shadow(color: AppTheme.orange.opacity(0.3), radius: 12, y: 6)
        }
    }

    private var endSessionButton: some View {
        Button { showEndSessionAlert = true } label: {
            Text("End Session").font(.subheadline).foregroundStyle(Color.white.opacity(0.4))
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
            // All sessions done — award task completion bonus (+50)
            guard let userId = userStore.currentUser?.id else {
                sessionComplete = true
                return
            }
            Task {
                // Mark task complete
                await taskStore.toggleCompletion(for: task)
                // Award completion bonus points
                await userStore.updateFocusPoints(by: pointsOnCompletion)
                // Record focus time and points in ProgressStore
                await progressStore.addFocusTime(minutes: totalFocusMinutes, userId: userId)
                await progressStore.addPointsEarned(points: pointsOnCompletion, userId: userId)
            }
            sessionComplete = true
        } else {
            // Session complete but more to go — award per-session points (+20) and show popup
            if let userId = userStore.currentUser?.id {
                Task {
                    await userStore.updateFocusPoints(by: pointsPerSession)
                    await progressStore.addPointsEarned(points: pointsPerSession, userId: userId)
                }
            }
            showPomodoroCompletePopup = true
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

// MARK: - Pomodoro Session Complete Popup

struct PomodoroSessionPopup: View {
    let sessionNumber: Int
    let totalSessions: Int
    let pointsEarned: Int
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {} // block taps

            VStack(spacing: 24) {
                Spacer()

                // Badge icon
                ZStack {
                    Circle()
                        .fill(AppTheme.sage.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.sage)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: appeared)
                }

                VStack(spacing: 8) {
                    Text("Well done!")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.warmTextPrimary)

                    Text("Session \(sessionNumber) of \(totalSessions) complete.\nTake a moment to notice how\nyour body feels")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Text("+ \(pointsEarned) Focus Points")
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.orange, AppTheme.amber],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 8)

                Spacer()

                Button(action: onContinue) {
                    Text("Start Break")
                }
                .buttonStyle(GradientButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
            .shadow(color: Color.black.opacity(0.3), radius: 30, y: 10)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Overwhelmed Sheet
struct OverwhelmedSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.rose.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 40)).foregroundStyle(AppTheme.rose)
            }
            .padding(.top, 32)

            VStack(spacing: 8) {
                Text("Feeling a little overwhelmed?").font(.title3.bold()).multilineTextAlignment(.center)
                Text("You seem quite distracted right now. Would you like to take a short meditation break and reset your focus?")
                    .font(.subheadline).foregroundStyle(AppTheme.warmTextSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button {
                    // Navigate to calm centre
                } label: {
                    Text("Go to Calm Centre")
                }
                .buttonStyle(GradientButtonStyle(gradient: LinearGradient(
                    colors: [AppTheme.sage, Color(hex: "10B981")],
                    startPoint: .leading,
                    endPoint: .trailing
                )))
                .padding(.horizontal, 32)

                Button { dismiss() } label: {
                    Text("Stay in session").font(.subheadline).foregroundStyle(AppTheme.warmTextSecondary)
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
    let pointsEarned: Int
    let onDismiss: () -> Void

    @State private var celebrationAppeared = false

    var body: some View {
        ZStack {
            // Rich celebration gradient background
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1C1917")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                VStack(spacing: 8) {
                    Text("Well Done").font(.largeTitle.bold()).foregroundStyle(.white)
                    Text("Focus session complete").font(.subheadline).foregroundStyle(Color.white.opacity(0.5))
                }

                ZStack {
                    // Glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.amber.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(celebrationAppeared ? 1.0 : 0.6)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.3), value: celebrationAppeared)

                    Circle()
                        .fill(AppTheme.celebrationGradient)
                        .frame(width: 150, height: 150)
                        .shadow(color: AppTheme.amber.opacity(0.5), radius: 30)
                        .scaleEffect(celebrationAppeared ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: celebrationAppeared)

                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill").font(.system(size: 32)).foregroundStyle(.white.opacity(0.9))
                        Text("\(totalSessions) Session\(totalSessions > 1 ? "s" : "")").font(.headline.bold()).foregroundStyle(.white)
                        Text("COMPLETED").font(.caption.bold()).foregroundStyle(.white.opacity(0.85)).kerning(1.2)
                    }
                }

                HStack(spacing: 0) {
                    statItem(label: "TOTAL FOCUS", value: "\(totalFocusMinutes)m", icon: "clock.fill", color: AppTheme.orange)
                    Divider().frame(height: 40).overlay(Color.white.opacity(0.1))
                    statItem(label: "DISTRACTIONS", value: "\(distractedCount)", icon: "eye.slash.fill", color: AppTheme.rose)
                }
                .padding(.vertical, 20)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                .padding(.horizontal, 40)

                Text("+ \(pointsEarned) Focus Points")
                    .font(.title2.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.orange, AppTheme.amber],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                Button(action: onDismiss) {
                    Text("Go to Planner")
                }
                .buttonStyle(GradientButtonStyle())
                .padding(.horizontal, 32).padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { celebrationAppeared = true }
    }

    private func statItem(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(Color.white.opacity(0.4)).kerning(0.5)
            Text(value).font(.title3.bold()).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
