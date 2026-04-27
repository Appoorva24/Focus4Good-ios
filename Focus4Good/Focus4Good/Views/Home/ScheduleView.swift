import SwiftUI

struct ScheduleView: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    @State private var showAddTask = false
    @State private var showScanNotes = false
    @State private var selectedTask: UserTask?

    private var repetitiveTasks: [UserTask] {
        taskStore.tasks
            .filter { $0.repeatType != .never && !$0.isCompleted }
            .sorted { priorityOrder($0) < priorityOrder($1) }
    }

    private var todayTasks: [UserTask] {
        taskStore.todaysTasks
            .filter { $0.repeatType == .never }
            .sorted { priorityOrder($0) < priorityOrder($1) }
    }

    private func priorityOrder(_ task: UserTask) -> Int {
        switch task.priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        case .none: return 3
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if taskStore.isLoading && taskStore.tasks.isEmpty {
                    // Show a spinner while tasks are loading for the first time
                    VStack {
                        Spacer()
                        ProgressView("Loading tasks…")
                            .tint(AppTheme.orange)
                        Spacer()
                    }
                } else if taskStore.tasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }

            // Only show floating add button when tasks exist
            if !taskStore.tasks.isEmpty {
                floatingAddButton
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet()
        }
        .sheet(isPresented: $showScanNotes) {
            ScanNotesView()
        }
        .navigationDestination(item: $selectedTask) { task in
            PomodoroView(task: task)
        }
        .onAppear {
            // Refresh tasks whenever the schedule is opened
            guard let userId = userStore.currentUser?.id else { return }
            Task { await taskStore.fetchTasks(userId: userId) }
        }
    }

    // MARK: - Empty State (Manual + Scan buttons, NO floating button)

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(AppTheme.orange.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No tasks yet")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("Add your first task to get started")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            VStack(spacing: 16) {
                // Manual button
                Button {
                    showAddTask = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add Manually")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Create tasks one by one")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Scan from Handwritten Notes button
                Button {
                    showScanNotes = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title2)
                            .foregroundStyle(AppTheme.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scan from Handwritten Notes")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Use camera to scan your written task list")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.orange.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Task List

    private var upcomingTasks: [UserTask] {
        // Tasks not matching today and not repetitive — shown in an "Upcoming" section
        let cal = Calendar.current
        return taskStore.tasks
            .filter {
                $0.repeatType == .never &&
                !$0.isCompleted &&
                !(cal.isDate($0.scheduledDate ?? Date.distantPast, inSameDayAs: Date()))
            }
            .sorted { priorityOrder($0) < priorityOrder($1) }
    }

    private var taskList: some View {
        List {
            if !repetitiveTasks.isEmpty {
                Section {
                    ForEach(repetitiveTasks) { task in
                        TaskRowView(task: task, selectedTask: $selectedTask)
                    }
                } header: {
                    Text("Repetitive").font(.headline).foregroundStyle(AppTheme.textPrimary).textCase(nil)
                }
            }

            if !todayTasks.isEmpty {
                Section {
                    ForEach(todayTasks) { task in
                        TaskRowView(task: task, selectedTask: $selectedTask)
                    }
                } header: {
                    HStack {
                        Text("Today").font(.headline).foregroundStyle(AppTheme.textPrimary).textCase(nil)
                        Spacer()
                        let remaining = todayTasks.filter { !$0.isCompleted }.count
                        if remaining > 0 {
                            Text("\(remaining) Remaining").font(.caption.bold()).foregroundStyle(AppTheme.orange)
                        }
                    }
                }
            }

            if !upcomingTasks.isEmpty {
                Section {
                    ForEach(upcomingTasks) { task in
                        TaskRowView(task: task, selectedTask: $selectedTask)
                    }
                } header: {
                    Text("Upcoming").font(.headline).foregroundStyle(AppTheme.textPrimary).textCase(nil)
                }
            }

            // Fallback: if no section matched, show all tasks
            if repetitiveTasks.isEmpty && todayTasks.isEmpty && upcomingTasks.isEmpty {
                Section {
                    ForEach(taskStore.tasks) { task in
                        TaskRowView(task: task, selectedTask: $selectedTask)
                    }
                } header: {
                    Text("All Tasks").font(.headline).foregroundStyle(AppTheme.textPrimary).textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Floating Add Button (only shown when tasks exist)

    private var floatingAddButton: some View {
        Button { showAddTask = true } label: {
            Image(systemName: "plus")
                .font(.title2.bold()).foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AppTheme.orange))
                .shadow(color: AppTheme.orange.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 24).padding(.bottom, 32)
    }
}

struct TaskRowView: View {
    let task: UserTask
    @Binding var selectedTask: UserTask?
    @Environment(TaskStore.self) private var taskStore

    var body: some View {
        HStack(spacing: 14) {
            Button {
                Task { await taskStore.toggleCompletion(for: task) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(task.isCompleted ? AppTheme.orange : Color(.systemGray3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if task.isCompleted {
                        Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(AppTheme.orange)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if task.repeatType != .never {
                        tagView(task.repeatType.displayName, color: .purple)
                    }
                    if let time = task.scheduledTime {
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.caption2)
                            Text(time.formatted(.dateTime.hour().minute())).font(.caption)
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    if let duration = task.estimatedDuration {
                        HStack(spacing: 3) {
                            Image(systemName: "timer").font(.caption2)
                            Text("\(duration)m").font(.caption)
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            Spacer()
            Circle().fill(priorityColor).frame(width: 8, height: 8)

            if !task.isCompleted {
                Button { selectedTask = task } label: {
                    Image(systemName: "timer").font(.title3).foregroundStyle(AppTheme.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return AppTheme.orange
        case .low: return .blue
        case .none: return .clear
        }
    }

    private func tagView(_ text: String, color: Color) -> some View {
        Text(text).font(.caption2.bold()).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}
