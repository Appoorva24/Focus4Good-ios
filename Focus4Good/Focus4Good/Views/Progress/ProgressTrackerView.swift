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

                    Spacer()

                    TasksGauge(
                        completed: progress?.tasksCompleted ?? 0,
                        goal:      progress?.taskGoal ?? 1
                    )
                    .frame(height: 100)

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .shadow(color: AppTheme.shadow, radius: 8, y: 2)

                // Time Spent Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Spent")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    TimeRow(
                        systemImage: "person.fill",
                        label:       "Focus",
                        minutes:     progress?.focusTimeMinutes ?? 0
                    )

                    TimeRow(
                        systemImage: "figure.mind.and.body",
                        label:       "Calm",
                        minutes:     progress?.calmCentreMinutes ?? 0
                    )

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .shadow(color: AppTheme.shadow, radius: 8, y: 2)
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
                    value:       "\(userStore.currentUser?.focusPoints ?? 0)",
                    label:       "Focus Points"
                )
                MetricCard(
                    systemImage: "flame.fill",
                    value:       "\(userStore.currentUser?.bestStreak ?? 0) Days",
                    label:       "Best Streak"
                )
            }
        }
    }

}

// MARK: - Tasks Gauge

private struct TasksGauge: View {
    let completed: Int
    let goal: Int

    var body: some View {
        Gauge(value: Double(min(completed, goal)), in: 0...Double(max(goal, 1))) {
            EmptyView()
        } currentValueLabel: {
            VStack(spacing: 2) {
                Text("\(completed)")
                    .font(.title.bold())
                Text("/ \(goal)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(AppTheme.orange)
        .scaleEffect(1.8)
    }
}

// MARK: - Time Row

private struct TimeRow: View {
    let systemImage: String
    let label: String
    let minutes: Int

    private var formatted: String {
        String(format: "%02d:%02d hrs", minutes / 60, minutes % 60)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.orange)
                .frame(width: 30, height: 30)
                .background(AppTheme.accentLight)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatted)
                    .font(.subheadline.weight(.semibold))
            }
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
                .foregroundStyle(AppTheme.orange)
                .frame(width: 54, height: 54)
                .background(AppTheme.accentLight)
                .clipShape(Circle())

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 8, y: 2)
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
