import SwiftUI

// MARK: - Theme

private enum Theme {
    static let accent = Color(red: 0.91, green: 0.57, blue: 0.23)
    static let accentLight = Color(red: 0.91, green: 0.57, blue: 0.23).opacity(0.15)
    static let cardBg = Color(.systemBackground)
    static let shadow = Color.black.opacity(0.05)
    static let radius: CGFloat = 16
}

// MARK: - Period

enum ProgressPeriod: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    var id: String { rawValue }
}

// MARK: - ProgressTrackerView

struct ProgressTrackerView: View {
    @Environment(ProgressStore.self) private var progressStore
    @State private var selectedPeriod: ProgressPeriod = .weekly

    private var progress: UserProgress? {
        switch selectedPeriod {
        case .weekly: return progressStore.weeklyProgress
        case .monthly: return progressStore.monthlyProgress
        }
    }

    private var user: User? { UserStore.shared.currentUser }

    private var milestoneInfo: (milestone: Milestone, ratio: Double)? {
        let store = GamificationStore.shared
        guard let m = store.nextMilestone else { return nil }
        let um = store.userMilestones.first { $0.milestoneId == m.id }
        let ratio = m.pointsRequired > 0
            ? min(Double(um?.progress ?? 0) / Double(m.pointsRequired), 1.0)
            : 0
        return (m, ratio)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ProgressPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        statisticsSection
                        keyMetricsSection
                        nextMilestoneSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.title3.bold())

            HStack(alignment: .top, spacing: 12) {
                // Tasks Completed Card
                VStack(spacing: 12) {
                    Text("Tasks Completed")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    TasksGauge(
                        completed: progress?.tasksCompleted ?? 0,
                        goal: progress?.taskGoal ?? 1
                    )
                    .frame(height: 100)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Theme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                .shadow(color: Theme.shadow, radius: 8, y: 2)

                // Time Spent Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Spent")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    TimeRow(
                        systemImage: "person.fill",
                        minutes: progress?.focusTimeMinutes ?? 0
                    )

                    TimeRow(
                        systemImage: "person.2.fill",
                        minutes: progress?.calmCentreMinutes ?? 0
                    )

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                .shadow(color: Theme.shadow, radius: 8, y: 2)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Key Metrics

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.title3.bold())

            HStack(spacing: 12) {
                MetricCard(
                    systemImage: "circle.circle",
                    value: "\(user?.focusPoints ?? 0)",
                    label: "Focus Points"
                )
                MetricCard(
                    systemImage: "flame.fill",
                    value: "\(user?.bestStreak ?? 0) Days",
                    label: "Best Streak"
                )
            }
        }
    }

    // MARK: - Next Milestone

    private var nextMilestoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Milestone")
                .font(.title3.bold())

            if let info = milestoneInfo {
                MilestoneCard(
                    milestone: info.milestone,
                    progress: info.ratio
                )
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Theme.accent.opacity(0.5))
                    Text("No upcoming milestones")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Theme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                .shadow(color: Theme.shadow, radius: 8, y: 2)
            }
        }
    }
}

// MARK: - Tasks Gauge (Real SwiftUI Gauge)

private struct TasksGauge: View {
    let completed: Int
    let goal: Int

    var body: some View {
        Gauge(value: Double(min(completed, goal)), in: 0...Double(max(goal, 1))) {
            EmptyView()
        } currentValueLabel: {
            Text("\(completed)")
                .font(.title.bold())
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(Theme.accent)
        .scaleEffect(1.8)
    }
}

// MARK: - Time Row

private struct TimeRow: View {
    let systemImage: String
    let minutes: Int

    private var formatted: String {
        String(format: "%02d:%02d hrs", minutes / 60, minutes % 60)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .background(Theme.accentLight)
                .clipShape(Circle())

            Text(formatted)
                .font(.subheadline.weight(.semibold))
        }
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let systemImage: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 54, height: 54)
                .background(Theme.accentLight)
                .clipShape(Circle())

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .shadow(color: Theme.shadow, radius: 8, y: 2)
    }
}

// MARK: - Milestone Card

private struct MilestoneCard: View {
    let milestone: Milestone
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: milestone.imageUrl.isEmpty ? "book.fill" : milestone.imageUrl)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 46, height: 46)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.name)
                        .font(.headline)

                    Text(milestone.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            // Progress
            VStack(spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.accent)
                }

                ProgressView(value: progress)
                    .tint(Theme.accent)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(18)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .shadow(color: Theme.shadow, radius: 8, y: 2)
    }
}

// MARK: - Preview

#Preview {
    let store = ProgressStore.shared
    let userId = UUID()

    let _ = {
        store.progressRecords = [
            UserProgress(
                userId: userId,
                periodType: "weekly",
                periodStart: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
                tasksCompleted: 52,
                focusTimeMinutes: 145,
                calmCentreMinutes: 95,
                focusPointsEarned: 820,
                taskGoal: 75
            ),
            UserProgress(
                userId: userId,
                periodType: "monthly",
                periodStart: Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date(),
                tasksCompleted: 291,
                focusTimeMinutes: 580,
                calmCentreMinutes: 320,
                focusPointsEarned: 4520,
                taskGoal: 400
            )
        ]
    }()

    return ProgressTrackerView()
        .environment(store)
}
