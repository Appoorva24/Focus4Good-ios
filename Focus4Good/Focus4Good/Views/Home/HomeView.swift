import SwiftUI

enum HomeDestination: Hashable {
    case schedule
    case ngoList
}

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(TaskStore.self) private var taskStore
    @Environment(VolunteerStore.self) private var volunteerStore
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false

    private var upcomingTasksForToday: [UserTask] {
        let now = Date()
        let cal = Calendar.current
        let currentHour = cal.component(.hour, from: now)
        let currentMinute = cal.component(.minute, from: now)
        let currentTimeMinutes = currentHour * 60 + currentMinute
        
        return taskStore.todaysTasks
            .filter { task in
                if taskStore.isTaskCompleted(task, on: now) { return false }
                guard let scheduledTime = task.scheduledTime else { return true } // Show tasks with no time
                let taskHour = cal.component(.hour, from: scheduledTime)
                let taskMinute = cal.component(.minute, from: scheduledTime)
                let taskTimeMinutes = taskHour * 60 + taskMinute
                return taskTimeMinutes >= currentTimeMinutes
            }
            .sorted { task1, task2 in
                guard let time1 = task1.scheduledTime else { return false }
                guard let time2 = task2.scheduledTime else { return true }
                return time1 < time2
            }
            .prefix(3)
            .map { $0 }
    }

    private var todayGoalProgress: Double {
        let today = Date()
        let todayTasks = taskStore.todaysTasks
        let total = todayTasks.count
        guard total > 0 else { return 0 }
        return Double(todayTasks.filter { taskStore.isTaskCompleted($0, on: today) }.count) / Double(total)
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
                    ngoConnectCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8) 
            }
            .background(Color(.systemBackground))
            .navigationTitle(greetingText)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .schedule:
                    ScheduleView()
                case .ngoList:
                    NGOListView()
                }
            }
        }
    }

    // MARK: - Quote
    private var quoteSection: some View {
        Text("\(Text("\"You don't need to do everything. ").foregroundStyle(AppTheme.textSecondary))\(Text("Just start with one thing.").foregroundStyle(AppTheme.orange).bold())\(Text("\"").foregroundStyle(AppTheme.textSecondary))")
            .font(.subheadline)
    }

    
    // MARK: - Planner Card
    private var plannerCard: some View {
        Button { navigationPath.append(HomeDestination.schedule) } label: {
            VStack(spacing: 0) {
                HStack {
                    Text("Today's Plan")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.orange)

                VStack(alignment: .leading, spacing: 14) {
                    if upcomingTasksForToday.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(AppTheme.orange)
                            Text("No upcoming tasks today")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    } else {
                        ForEach(upcomingTasksForToday) { task in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(AppTheme.orange, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        if taskStore.isTaskCompleted(task, on: Date()) {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(AppTheme.orange)
                                        }
                                    }
                                Text(task.title)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                            }
                        }
                    }

                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add a new task")
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.orange.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: [6]))
                    )
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color(.systemBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.orange.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats
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


    // MARK: - NGO Connect
    private var ngoConnectCard: some View {
        Button { navigationPath.append(HomeDestination.ngoList) } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Image("ngo")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Image(systemName: "lock.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                        .padding(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("NGO Connect")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Focus Points")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

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
                        Text("\(userStore.currentUser?.focusPoints ?? 0)")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.orange)
                        Spacer()
                        Text("10,000")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 12)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let progress: Double

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.orange, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: progress)
                Text(value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(width: 80, height: 80)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.systemGray4), lineWidth: 0.5))
        )
    }
}
