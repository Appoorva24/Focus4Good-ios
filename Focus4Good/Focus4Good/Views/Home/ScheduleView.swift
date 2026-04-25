import SwiftUI

struct ScheduleView: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    @State private var showAddTask = false

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
                if taskStore.tasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            
            // Show floating button only when tasks exist
            if !taskStore.tasks.isEmpty {
                floatingAddButton
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet()
        }

        .navigationDestination(item: $selectedTask) { task in
            PomodoroView(task: task)
        }
    }

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
                // Manual button - clickable
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
                

            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
        }
        .listStyle(.insetGrouped)
    }

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
