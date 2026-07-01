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

    private var greetingEmoji: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "🌅"
        case 12..<17: return "☀️"
        default: return "🌙"
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    quoteSection
                        .staggeredFadeIn(index: 0)
                    plannerCard
                        .staggeredFadeIn(index: 1)
                    statsRow
                        .staggeredFadeIn(index: 2)
                    ngoConnectCard
                        .staggeredFadeIn(index: 3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(homeBackground)
            .navigationTitle("\(greetingEmoji) \(greetingText)")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.orange)
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

    // MARK: - Background

    private var homeBackground: some View {
        ZStack {
            AppTheme.pageGradient
                .ignoresSafeArea()

            // Subtle decorative orbs
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(AppTheme.orange.opacity(0.06))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: 60, y: -40)
                }
                Spacer()
                HStack {
                    Circle()
                        .fill(AppTheme.sage.opacity(0.05))
                        .frame(width: 180, height: 180)
                        .blur(radius: 50)
                        .offset(x: -40, y: 40)
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Quote
    private var quoteSection: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.buttonGradient)
                .frame(width: 3, height: 40)

            Text("\(Text("\"You don't need to do everything. ").foregroundStyle(AppTheme.warmTextSecondary))\(Text("Just start with one thing.").foregroundStyle(AppTheme.orange).bold())\(Text("\"").foregroundStyle(AppTheme.warmTextSecondary))")
                .font(.subheadline)
        }
        .padding(16)
        .glassCard()
    }

    
    // MARK: - Planner Card
    private var plannerCard: some View {
        Button { navigationPath.append(HomeDestination.schedule) } label: {
            VStack(spacing: 0) {
                HStack {
                    Text("Today's Plan")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.buttonGradient)

                VStack(alignment: .leading, spacing: 14) {
                    if upcomingTasksForToday.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.sage)
                            Text("No upcoming tasks today")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.warmTextSecondary)
                        }
                    } else {
                        ForEach(upcomingTasksForToday) { task in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(AppTheme.orange, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        if taskStore.isTaskCompleted(task, on: Date()) {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(AppTheme.sage)
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
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.orange.opacity(0.3), style: StrokeStyle(lineWidth: 1.2, dash: [6]))
                    )
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: AppTheme.orange.opacity(0.1), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 14) {
            StatCard(
                title: "Focus Points",
                value: "\(userStore.currentUser?.focusPoints ?? 0)",
                progress: focusPointsProgress,
                ringColor: AppTheme.orange,
                ringGradient: [Color(hex: "F97316"), Color(hex: "F59E0B")]
            )
            StatCard(
                title: "Today's Goal",
                value: "\(Int(todayGoalProgress * 100))%",
                progress: todayGoalProgress,
                ringColor: AppTheme.sage,
                ringGradient: [Color(hex: "22C55E"), Color(hex: "10B981")]
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            // Gradient overlay on image
                            LinearGradient(
                                colors: [.clear, Color.black.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        )

                    Image(systemName: "lock.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(.ultraThinMaterial))
                        .padding(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("NGO Connect")
                        .font(.headline)
                        .foregroundStyle(AppTheme.warmTextPrimary)

                    Text("Focus Points")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warmTextSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppTheme.orange.opacity(0.15)).frame(height: 6)
                            Capsule()
                                .fill(AppTheme.buttonGradient)
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
                            .foregroundStyle(AppTheme.warmTextSecondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 12)
            }
            .padding(16)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let progress: Double
    var ringColor: Color = AppTheme.orange
    var ringGradient: [Color] = [Color(hex: "F97316"), Color(hex: "F59E0B")]

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(ringColor.opacity(0.12), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: ringGradient + [ringGradient.first ?? ringColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: progress)
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warmTextPrimary)
            }
            .frame(width: 80, height: 80)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.warmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }
}
