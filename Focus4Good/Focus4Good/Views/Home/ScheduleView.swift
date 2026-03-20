
import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var userStore: UserStore
    @State private var showAddTask = false
    @State private var selectedTask: UserTask? = nil

    private var repetitiveTasks: [UserTask] {
        taskStore.tasks.filter { $0.repeatType != .never && !$0.isCompleted }
    }

    private var todayTasks: [UserTask] {
        taskStore.todaysTasks
            .filter { $0.repeatType == .never }
            .sorted {
                let order: [UserTask.Priority] = [.high, .medium, .low, .none]
                return (order.firstIndex(of: $0.priority) ?? 3) < (order.firstIndex(of: $1.priority) ?? 3)
            }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if taskStore.todaysTasks.isEmpty && repetitiveTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            floatingAddButton
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet()
                .environmentObject(taskStore)
                .environmentObject(userStore)
        }
        .navigationDestination(item: $selectedTask) { task in
            PomodoroView(task: task)
                .environmentObject(taskStore)
                .environmentObject(userStore)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(AppTheme.orange.opacity(0.5))
            Text("No tasks for today")
                .font(.title3.bold())
            Text("Tap + to add your first task")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
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
                            .environmentObject(taskStore)
                    }
                } header: {
                    Text("Repetitive")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .textCase(nil)
                }
            }

            if !todayTasks.isEmpty {
                Section {
                    ForEach(todayTasks) { task in
                        TaskRowView(task: task, selectedTask: $selectedTask)
                            .environmentObject(taskStore)
                    }
                } header: {
                    HStack {
                        Text("Today")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .textCase(nil)
                        Spacer()
                        let remaining = todayTasks.filter { !$0.isCompleted }.count
                        if remaining > 0 {
                            Text("\(remaining) Remaining")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.orange)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var floatingAddButton: some View {
        Button {
            showAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AppTheme.orange))
                .shadow(color: AppTheme.orange.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 32)
    }
}

struct TaskRowView: View {
    let task: UserTask
    @Binding var selectedTask: UserTask?
    @EnvironmentObject private var taskStore: TaskStore

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
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.orange)
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

            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            if !task.isCompleted {
                Button {
                    selectedTask = task
                } label: {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(AppTheme.orange)
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
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}
