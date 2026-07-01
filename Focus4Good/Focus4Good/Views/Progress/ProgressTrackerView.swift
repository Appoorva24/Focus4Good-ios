import SwiftUI

// MARK: - Period

enum ProgressPeriod: String, CaseIterable, Identifiable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
    var id: String { rawValue }
}

// MARK: - ProgressTrackerView

struct ProgressTrackerView: View {
    @Environment(ProgressStore.self)      private var progressStore
    @Environment(UserStore.self)          private var userStore

    @State private var selectedPeriod: ProgressPeriod = .weekly

    private var progress: UserProgress? {
        switch selectedPeriod {
        case .weekly:  return progressStore.weeklyProgress
        case .monthly: return progressStore.monthlyProgress
        }
    }

    // Motivational thoughts for the bottom card
    private let thoughts: [(title: String, subtitle: String)] = [
        ("Small steps, big change.", "Consistency today builds the focus you'll be proud of tomorrow."),
        ("Every minute counts.", "Your dedication is planting seeds of transformation."),
        ("Stay present, stay powerful.", "Focus is not about perfection, it's about progress.")
    ]

    private var currentThought: (title: String, subtitle: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return thoughts[dayOfYear % thoughts.count]
    }

    // Motivational message based on task progress
    private var motivationalMessage: String {
        let completed = progress?.tasksCompleted ?? 0
        let goal = progress?.taskGoal ?? 1
        let ratio = Double(completed) / Double(max(goal, 1))
        if ratio >= 1.0 {
            return "Amazing! You've crushed your goal!"
        } else if ratio >= 0.5 {
            return "Great progress! Keep it up!"
        } else if completed > 0 {
            return "Nice start! Keep the momentum going!"
        } else {
            return "Keep going! You're building momentum."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                // Segmented Picker
                periodPicker

                // Overview Section
                overviewSection

                // Key Metrics Section
                keyMetricsSection

                // Thought Card
                thoughtCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(progressBackground)
    }

    // MARK: - Background with wave decorations

    private var progressBackground: some View {
        ZStack {
            // Warm gradient background — adapts to dark mode
            LinearGradient(
                colors: [
                    AppTheme.pageBgTop,
                    AppTheme.pageBgMid,
                    AppTheme.pageBgBot
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                // Stronger wave decoration at the bottom
                WaveShape()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.orange.opacity(0.10), AppTheme.orange.opacity(0.18)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 140)
                    .ignoresSafeArea(edges: .bottom)

                // Second wave layer for depth
                WaveShape()
                    .fill(AppTheme.orange.opacity(0.06))
                    .frame(height: 80)
                    .offset(y: -40)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progress")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color(.label))

            Text("Track your focus. Celebrate growth.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Period Picker (Native glass segmented control)

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(ProgressPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title3.bold())

            HStack(alignment: .top, spacing: 12) {
                // Tasks Completed Card
                tasksCompletedCard

                // Time Spent Card
                timeSpentCard
            }
        }
    }

    // MARK: - Tasks Completed Card

    private var tasksCompletedCard: some View {
        VStack(spacing: 8) {
            Text("Tasks Completed")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.cardLabel)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Custom Circular Progress Ring
            CircularProgressRing(
                completed: progress?.tasksCompleted ?? 0,
                goal: progress?.taskGoal ?? 1
            )
            .frame(width: 100, height: 100)
            .padding(.vertical, 4)

            Text(motivationalMessage)
                .font(.caption2)
                .foregroundStyle(AppTheme.warmTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 200)
        .glassCard()
    }

    // MARK: - Time Spent Card

    private var timeSpentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Spent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.cardLabel)

            Spacer()

            TimeRow(
                systemImage: "person.fill",
                label:       "Focus",
                minutes:     progress?.focusTimeMinutes ?? 0,
                color:       AppTheme.orange
            )

            TimeRow(
                systemImage: "figure.mind.and.body",
                label:       "Calm",
                minutes:     progress?.calmCentreMinutes ?? 0,
                color:       AppTheme.sage
            )

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .glassCard()
    }

    // MARK: - Key Metrics

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.title3.bold())

            HStack(spacing: 12) {
                MetricCard(
                    systemImage: "scope",
                    value:       "\(userStore.currentUser?.focusPoints ?? 0)",
                    label:       "Focus Points",
                    color:       AppTheme.orange
                )
                MetricCard(
                    systemImage: "flame.fill",
                    value:       "\(userStore.currentUser?.bestStreak ?? 0) Days",
                    label:       "Best Streak",
                    color:       AppTheme.amber
                )
            }
        }
    }

    // MARK: - Thought Card

    private var thoughtCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentThought.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.warmTextPrimary)

                Text(currentThought.subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Potted plant image
            Image("potted_plant")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.thoughtCardStart, AppTheme.thoughtCardEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.orange.opacity(0.12), radius: 10, y: 3)
    }
}

// MARK: - Circular Progress Ring

private struct CircularProgressRing: View {
    let completed: Int
    let goal: Int

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(completed) / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(AppTheme.orange.opacity(0.12), style: StrokeStyle(lineWidth: 10, lineCap: .round))

            // Progress arc — multi-color gradient
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.orange, AppTheme.amber, AppTheme.sage, AppTheme.orange],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: fraction)

            // Center label
            VStack(spacing: 2) {
                Text("\(completed)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warmTextPrimary)
                Text("/ \(goal)")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
        }
    }
}

// MARK: - Time Row

private struct TimeRow: View {
    let systemImage: String
    let label: String
    let minutes: Int
    var color: Color = AppTheme.orange

    private var formatted: String {
        String(format: "%02d:%02d hrs", minutes / 60, minutes % 60)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                Text(formatted)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.warmTextPrimary)
            }
        }
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let systemImage: String
    let value: String
    let label: String
    var color: Color = AppTheme.orange

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.warmTextPrimary)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.warmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }
}

// MARK: - Wave Shape (Background decoration)

private struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h * 0.4))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.3),
            control1: CGPoint(x: w * 0.3, y: 0),
            control2: CGPoint(x: w * 0.7, y: h * 0.8)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Card Wave Shape (Thought card interior wave)

private struct CardWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h * 0.5))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.3),
            control1: CGPoint(x: w * 0.25, y: 0),
            control2: CGPoint(x: w * 0.75, y: h)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    let progressStore     = ProgressStore.shared
    let userStore         = UserStore.shared
    let userId            = UUID()

    let _ = {
        progressStore.progressRecords = [
            UserProgress(
                userId: userId,
                periodType: "weekly",
                periodStart: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
                tasksCompleted: 12,
                focusTimeMinutes: 145,
                calmCentreMinutes: 45,
                focusPointsEarned: 320,
                taskGoal: 30
            ),
            UserProgress(
                userId: userId,
                periodType: "monthly",
                periodStart: Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date(),
                tasksCompleted: 48,
                focusTimeMinutes: 580,
                calmCentreMinutes: 120,
                focusPointsEarned: 1280,
                taskGoal: 120
            )
        ]
    }()

    return ProgressTrackerView()
        .environment(progressStore)
        .environment(userStore)
}
