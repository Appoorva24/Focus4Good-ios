import SwiftUI

struct TaskPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    
    @Binding var tasks: [ParsedTask]
    let onConfirm: () -> Void
    
    @State private var editingTask: ParsedTask?
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if tasks.isEmpty {
                    emptyState
                } else {
                    tasksList
                }
                
                if isSaving {
                    savingOverlay
                }
            }
            .navigationTitle("Review Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add All") {
                        saveAllTasks()
                    }
                    .font(.headline)
                    .foregroundStyle(tasks.isEmpty ? AppTheme.textSecondary : AppTheme.orange)
                    .disabled(tasks.isEmpty || isSaving)
                }
            }
            .sheet(item: $editingTask) { task in
                EditTaskSheet(task: task, onSave: { updatedTask in
                    updateTask(updatedTask)
                })
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(AppTheme.orange.opacity(0.5))
            
            Text("No tasks found")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            
            Text("We couldn't detect any tasks in the scanned image")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Tasks List
    private var tasksList: some View {
        List {
            Section {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskPreviewRow(task: task, index: index + 1)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTask(task)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            editingTask = task
                        }
                }
            } header: {
                HStack {
                    Text("\(tasks.count) Tasks Found")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .textCase(nil)
                    Spacer()
                }
            } footer: {
                Text("Tap to edit • Swipe to delete")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Saving Overlay
    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("Adding tasks...")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray))
            )
        }
    }
    
    // MARK: - Actions
    
    private func saveAllTasks() {
        isSaving = true
        
        Task {
            for parsedTask in tasks where parsedTask.isValid {
                let task = UserTask(
                    userId: userStore.currentUser?.id ?? DummyData.currentUser.id,
                    categoryId: nil,
                    title: parsedTask.taskName,
                    scheduledDate: Date(), // Today by default
                    scheduledTime: parsedTask.time,
                    repeatType: .never,
                    priority: .none,
                    isCompleted: false,
                    estimatedDuration: 25,
                    createdAt: Date()
                )
                
                await taskStore.addTask(task)
            }
            
            // Small delay for better UX
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            isSaving = false
            onConfirm()
            dismiss()
        }
    }
    
    private func deleteTask(_ task: ParsedTask) {
        withAnimation {
            tasks.removeAll { $0.id == task.id }
        }
    }
    
    private func updateTask(_ updatedTask: ParsedTask) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
        }
    }
}

// MARK: - Task Preview Row
struct TaskPreviewRow: View {
    let task: ParsedTask
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Task number badge
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.orange))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                
                if let time = task.time {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(time.formatted(.dateTime.hour().minute()))
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.orange)
                } else {
                    Text("No time set")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Task Sheet
struct EditTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let task: ParsedTask
    let onSave: (ParsedTask) -> Void
    
    @State private var editedName: String
    @State private var editedTime: Date
    @State private var hasTime: Bool
    
    init(task: ParsedTask, onSave: @escaping (ParsedTask) -> Void) {
        self.task = task
        self.onSave = onSave
        
        _editedName = State(initialValue: task.taskName)
        _editedTime = State(initialValue: task.time ?? Date())
        _hasTime = State(initialValue: task.time != nil)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Task Name", text: $editedName)
                        .font(.body)
                } header: {
                    Text("Task Name").textCase(nil)
                }
                
                Section {
                    Toggle(isOn: $hasTime.animation()) {
                        Label("Time", systemImage: "clock")
                    }
                    .tint(AppTheme.orange)
                    
                    if hasTime {
                        DatePicker(
                            "",
                            selection: $editedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .tint(AppTheme.orange)
                    }
                } header: {
                    Text("Time").textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.headline)
                    .foregroundStyle(editedName.isEmpty ? AppTheme.textSecondary : AppTheme.orange)
                    .disabled(editedName.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedTask = task
        updatedTask.taskName = editedName
        updatedTask.time = hasTime ? editedTime : nil
        
        onSave(updatedTask)
        dismiss()
    }
}
