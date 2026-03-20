import SwiftUI

struct AddTaskSheet: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var isDateEnabled = false
    @State private var selectedDate = Date()
    @State private var isTimeEnabled = false
    @State private var selectedTime = Date()
    @State private var repeatType: UserTask.RepeatType = .never
    @State private var priority: UserTask.Priority = .none
    @State private var selectedCategory: String = ""
    @State private var estimatedDuration: Int = 25
    @State private var showRepeatPicker = false
    @State private var showPriorityPicker = false
    @State private var showCategoryPicker = false

    private let categories = ["Study", "Work", "Personal", "Health", "Other"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Task Name", text: $title)
                        .font(.body)
                } header: {
                    Text("Task Name")
                        .textCase(nil)
                }

                Section {
                    Toggle(isOn: $isDateEnabled.animation()) {
                        Label("Date", systemImage: "calendar")
                    }
                    .tint(AppTheme.orange)

                    if isDateEnabled {
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.orange)
                    }

                    Toggle(isOn: $isTimeEnabled.animation()) {
                        Label("Time", systemImage: "clock")
                    }
                    .tint(AppTheme.orange)

                    if isTimeEnabled {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .tint(AppTheme.orange)
                    }
                } header: {
                    Text("Date & Time")
                        .textCase(nil)
                }

                Section {
                    pickerRow(
                        icon: "arrow.2.circlepath",
                        label: "Repeat",
                        value: repeatType.displayName,
                        action: { showRepeatPicker = true }
                    )
                } header: {
                    Text("Repeat")
                        .textCase(nil)
                }

                Section {
                    pickerRow(
                        icon: "line.3.horizontal.decrease",
                        label: "Priority",
                        value: priority.displayName,
                        action: { showPriorityPicker = true }
                    )

                    pickerRow(
                        icon: "square.grid.2x2",
                        label: "Category",
                        value: selectedCategory.isEmpty ? "None" : selectedCategory,
                        action: { showCategoryPicker = true }
                    )

                    HStack {
                        Label("Duration", systemImage: "timer")
                        Spacer()
                        Stepper("\(estimatedDuration) min", value: $estimatedDuration, in: 5...240, step: 5)
                            .fixedSize()
                    }
                } header: {
                    Text("More Options")
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveTask() }
                        .font(.headline)
                        .foregroundStyle(title.isEmpty ? AppTheme.textSecondary : AppTheme.orange)
                        .disabled(title.isEmpty)
                }
            }
            .confirmationDialog("Repeat", isPresented: $showRepeatPicker, titleVisibility: .visible) {
                ForEach(UserTask.RepeatType.allCases, id: \.self) { type in
                    Button(type.displayName) { repeatType = type }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Priority", isPresented: $showPriorityPicker, titleVisibility: .visible) {
                ForEach(UserTask.Priority.allCases, id: \.self) { p in
                    Button(p.displayName) { priority = p }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Category", isPresented: $showCategoryPicker, titleVisibility: .visible) {
                Button("None") { selectedCategory = "" }
                ForEach(categories, id: \.self) { cat in
                    Button(cat) { selectedCategory = cat }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func pickerRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(value)
                    .foregroundStyle(AppTheme.textSecondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func saveTask() {
        guard !title.isEmpty else { return }
        let userId = userStore.currentUser?.id ?? DummyData.currentUser.id
        let task = UserTask(
            userId: userId,
            categoryId: nil,
            title: title,
            scheduledDate: isDateEnabled ? selectedDate : Date(),
            scheduledTime: isTimeEnabled ? selectedTime : nil,
            repeatType: repeatType,
            priority: priority,
            isCompleted: false,
            estimatedDuration: estimatedDuration,
            createdAt: Date()
        )
        Task { await taskStore.addTask(task) }
        dismiss()
    }
}

extension UserTask.RepeatType {
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .weekly: return "Weekly"
        case .fortnightly: return "Fortnightly"
        case .monthly: return "Monthly"
        case .every3Months: return "Every 3 Months"
        case .every6Months: return "Every 6 Months"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}

extension UserTask.Priority {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}
