import SwiftUI

enum HomeDestination: Hashable {
    case schedule
    case ngoList
    case profile
}

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(TaskStore.self) private var taskStore
    @Environment(VolunteerStore.self) private var volunteerStore
    @State private var navigationPath = NavigationPath()

    private var todayHighPriorityTasks: [UserTask] {
        taskStore.todaysTasks
            .filter { $0.priority == .high && !$0.isCompleted }
            .prefix(3)
            .map { $0 }
    }

    private var todayGoalProgress: Double {
        let total = taskStore.todaysTasks.count
        guard total > 0 else { return 0 }
        return Double(taskStore.todaysTasks.filter { $0.isCompleted }.count) / Double(total)
    }

    private var focusPointsProgress: Double {
        min(Double(userStore.currentUser?.focusPoints ?? 0) / 1000.0, 1.0)
    }

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    quoteSection
                    plannerCard
                    statsRow
                    virtualClassroomCard
                    ngoConnectCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle(greetingText)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { navigationPath.append(HomeDestination.profile) } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .schedule:
                    ScheduleView()
                case .ngoList:
                    NGOListView()
                case .profile:
                    ProfileView()
                }
            }
        }
    }

    private var quoteSection: some View {
        Group {
            Text("\"You don't need to do everything. ")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            + Text("Just start with one thing.")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.orange)
            + Text("\"")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var plannerCard: some View {
        Button { navigationPath.append(HomeDestination.schedule) } label: {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Plan")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                if todayHighPriorityTasks.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle").foregroundStyle(AppTheme.orange)
                        Text("No high priority tasks today")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(todayHighPriorityTasks) { task in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(AppTheme.orange.opacity(0.7), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        if task.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(AppTheme.orange)
                                        }
                                    }
                                Text(task.title)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "plus.circle").foregroundStyle(AppTheme.orange)
                    Text("Add a new task").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 2)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "FFF3E8"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.orange.opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Focus Points",
                value: "\(userStore.currentUser?.focusPoints ?? 0)",
                progress: focusPointsProgress
            )
            StatCard(
                title: "Today's Goal",
                value: "\(Int(todayGoalProgress * 100))%",
                progress: todayGoalProgress
            )
        }
    }

    private var virtualClassroomCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .overlay {
                        Image("vc")
                            .resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 190).clipped()
                            .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.15)))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Image(systemName: "lock.fill")
                    .font(.subheadline.bold()).foregroundStyle(.white)
                    .padding(10).background(Circle().fill(Color.black.opacity(0.55)))
                    .padding(14)
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Virtual Classroom").font(.headline).foregroundStyle(AppTheme.textPrimary)
                    Text("Complete tasks and grow your virtual class").font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("Coming Soon")
                    .font(.caption.bold()).foregroundStyle(AppTheme.orange)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(AppTheme.orange.opacity(0.15)))
            }
            .padding(.top, 14).padding(.horizontal, 4)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
    }

    private var ngoConnectCard: some View {
        Button { navigationPath.append(HomeDestination.ngoList) } label: {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(maxWidth: .infinity).frame(height: 190)
                    .overlay {
                        Image("ngo")
                            .resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 190).clipped()
                            .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.2)))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text("NGO Connect").font(.headline).foregroundStyle(AppTheme.textPrimary)
                    Text("Focus Points").font(.caption).foregroundStyle(AppTheme.textSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 6)
                            Capsule()
                                .fill(AppTheme.orange)
                                .frame(
                                    width: geo.size.width * CGFloat(min(Double(userStore.currentUser?.focusPoints ?? 0) / 10000.0, 1.0)),
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(userStore.currentUser?.focusPoints ?? 0)").font(.caption.bold()).foregroundStyle(AppTheme.orange)
                        Spacer()
                        Text("10,000").font(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.top, 14).padding(.horizontal, 4)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let progress: Double

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color(.systemGray5), lineWidth: 9).frame(width: 86, height: 86)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.orange, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .frame(width: 86, height: 86)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: progress)
                Text(value).font(.system(size: 17, weight: .bold)).foregroundStyle(AppTheme.textPrimary)
            }
            Text(title).font(.caption).foregroundStyle(AppTheme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
    }
}
