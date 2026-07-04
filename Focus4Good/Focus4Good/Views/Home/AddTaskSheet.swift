import SwiftUI

struct AddTaskSheet: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var isDateEnabled = false
    @State private var selectedDate = Date()
    @State private var isEndDateEnabled = false
    @State private var endDate = Date()
    @State private var isTimeEnabled = false
    @State private var selectedTime = Date()
    @State private var repeatType: UserTask.RepeatType = .never
    @State private var estimatedDuration = 25
    @State private var showRepeatPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                
                List {
                    Section {
                        TextField("Task Name", text: $title).font(.body).foregroundStyle(AppTheme.warmTextPrimary)
                    } header: { Text("Task Name").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                    .listRowBackground(AppTheme.cardBg)

                Section {
                    Toggle(isOn: $isDateEnabled.animation()) {
                        Label("Start Date", systemImage: "calendar")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                    }
                    .tint(AppTheme.orange)

                    if isDateEnabled {
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.orange)
                    }

                    Toggle(isOn: $isEndDateEnabled.animation()) {
                        Label("End Date", systemImage: "calendar.badge.clock")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                    }
                    .tint(AppTheme.orange)

                    if isEndDateEnabled {
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.orange)
                    }

                    Toggle(isOn: $isTimeEnabled.animation()) {
                        Label("Time", systemImage: "clock")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                    }
                    .tint(AppTheme.orange)

                    if isTimeEnabled {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .tint(AppTheme.orange)
                    }
                } header: { Text("Date & Time").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)

                Section {
                    pickerRow(icon: "arrow.2.circlepath", label: "Repeat", value: repeatType.displayName) {
                        showRepeatPicker = true
                    }
                } header: { Text("Repeat").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)

                Section {
                    HStack {
                        Label("Duration", systemImage: "timer")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                        Spacer()
                        Stepper("\(estimatedDuration) min", value: $estimatedDuration, in: 25...125, step: 25)
                            .fixedSize()
                    }
                } header: { Text("More Options").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveTask() }
                        .font(.subheadline.bold())
                        .foregroundStyle(title.isEmpty ? AppTheme.warmTextSecondary : AppTheme.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .disabled(title.isEmpty)
                }
            }
            }
            .confirmationDialog("Repeat", isPresented: $showRepeatPicker, titleVisibility: .visible) {
                ForEach(UserTask.RepeatType.allCases, id: \.self) { type in
                    Button(type.displayName) { repeatType = type }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("Error Saving Task",
               isPresented: Binding(
                   get: { taskStore.errorMessage != nil },
                   set: { if !$0 { taskStore.errorMessage = nil } }
               ),
               presenting: taskStore.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func pickerRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon).foregroundStyle(AppTheme.warmTextPrimary)
                Spacer()
                Text(value).foregroundStyle(AppTheme.warmTextPrimary)
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(AppTheme.warmTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func saveTask() {
        guard !title.isEmpty else { return }
        
        // Guard: must have an authenticated user
        guard let userId = userStore.currentUser?.id else {
            taskStore.errorMessage = "Cannot save task: no authenticated user"
            return
        }
        
        let task = UserTask(
            userId: userId,
            categoryId: nil,
            title: title,
            scheduledDate: isDateEnabled ? selectedDate : Date(),
            endDate: isEndDateEnabled ? endDate : nil,
            scheduledTime: isTimeEnabled ? selectedTime : nil,
            repeatType: repeatType,
            priority: .none,
            isCompleted: false,
            estimatedDuration: estimatedDuration,
            createdAt: Date()
        )
        
        Task {
            // Clear previous errors
            taskStore.errorMessage = nil
            
            await taskStore.addTask(task)
            
            // Only dismiss if there's no error
            await MainActor.run {
                if taskStore.errorMessage == nil {
                    dismiss()
                }
            }
        }
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
