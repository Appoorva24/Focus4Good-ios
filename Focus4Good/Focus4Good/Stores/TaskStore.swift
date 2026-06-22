import Foundation
import Supabase

@MainActor
@Observable
class TaskStore {
    
    // MARK: - State
    var tasks: [UserTask] = []
    var categories: [TaskCategory] = []
    var isLoading = false
    var errorMessage: String?
    
    /// Per-day completion tracking for repeating tasks.
    /// Maps task ID → set of date strings ("yyyy-MM-dd") that are completed.
    var taskCompletions: [UUID: Set<String>] = [:]
    
    // MARK: - Computed (UNCHANGED — these still work!)
    var todaysTasks: [UserTask] {
        return tasks(for: Date())
    }
    var completedTasks: [UserTask] { tasks.filter { $0.isCompleted } }
    var pendingTasks: [UserTask] { tasks.filter { !$0.isCompleted } }
    func tasks(for category: TaskCategory) -> [UserTask] {
        tasks.filter { $0.categoryId == category.id }
    }
    
    // MARK: - Filter Tasks for a Specific Date
    func tasks(for date: Date) -> [UserTask] {
        let cal = Calendar.current
        let targetComponents = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        let targetYMD = targetComponents.year! * 10000 + targetComponents.month! * 100 + targetComponents.day!
        
        return tasks.filter { task in
            guard let startDate = task.scheduledDate else { return false }
            
            let startComponents = cal.dateComponents([.year, .month, .day, .weekday], from: startDate)
            let startYMD = startComponents.year! * 10000 + startComponents.month! * 100 + startComponents.day!
            
            // If the target date is before the task's start date, it shouldn't appear
            if targetYMD < startYMD { return false }
            
            // If the task has an end date, and the target date is strictly after it, it shouldn't appear
            if let endDate = task.endDate {
                let endComponents = cal.dateComponents([.year, .month, .day], from: endDate)
                let endYMD = endComponents.year! * 10000 + endComponents.month! * 100 + endComponents.day!
                if targetYMD > endYMD { return false }
            }
            
            if task.repeatType == .never {
                // For non-repeating tasks with an end date: show every day from start to end (inclusive).
                // For non-repeating tasks without an end date: show only on the exact start date.
                if task.endDate != nil {
                    return true // targetDate is already validated to be within [taskStart, taskEnd]
                } else {
                    return targetYMD == startYMD
                }
            }
            
            // Evaluate repetition rules
            let targetDayStart = cal.startOfDay(for: date)
            let taskDayStart = cal.startOfDay(for: startDate)
            let daysDifference = cal.dateComponents([.day], from: taskDayStart, to: targetDayStart).day ?? 0
            
            switch task.repeatType {
            case .never:
                return false
            case .daily:
                return true
            case .weekdays:
                let weekday = cal.component(.weekday, from: date)
                return weekday >= 2 && weekday <= 6 // 2=Mon, 6=Fri
            case .weekends:
                let weekday = cal.component(.weekday, from: date)
                return weekday == 1 || weekday == 7 // 1=Sun, 7=Sat
            case .weekly:
                return startComponents.weekday == targetComponents.weekday
            case .fortnightly:
                return startComponents.weekday == targetComponents.weekday && (daysDifference % 14 == 0)
            case .monthly:
                return startComponents.day == targetComponents.day
            case .every3Months:
                let monthDiff = cal.dateComponents([.month], from: taskDayStart, to: targetDayStart).month ?? 0
                return startComponents.day == targetComponents.day && (monthDiff % 3 == 0)
            case .every6Months:
                let monthDiff = cal.dateComponents([.month], from: taskDayStart, to: targetDayStart).month ?? 0
                return startComponents.day == targetComponents.day && (monthDiff % 6 == 0)
            case .yearly:
                return startComponents.day == targetComponents.day && startComponents.month == targetComponents.month
            case .custom:
                return false
            }
        }
    }
    
    static let shared = TaskStore()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    init() {}
    
    // MARK: - Date Normalization
    /// Normalizes scheduledDate and endDate to startOfDay to eliminate timezone drift
    /// from Supabase encode/decode cycles.
    private func normalizeTaskDates(_ task: UserTask) -> UserTask {
        let cal = Calendar.current
        var t = task
        if let date = t.scheduledDate {
            t.scheduledDate = cal.startOfDay(for: date)
        }
        if let date = t.endDate {
            t.endDate = cal.startOfDay(for: date)
        }
        return t
    }
    
    // MARK: - Fetch Tasks from Supabase
    func fetchTasks(userId: UUID) async {
        isLoading = true
        do {
            let fetched: [UserTask] = try await client
                .from("tasks")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            // Normalize all dates to startOfDay to avoid timezone drift
            tasks = fetched.map { normalizeTaskDates($0) }
            print("✅ Fetched \(fetched.count) tasks")
            for t in tasks {
                print("   📋 \(t.title) | scheduledDate=\(String(describing: t.scheduledDate)) | endDate=\(String(describing: t.endDate)) | repeat=\(t.repeatType)")
            }
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            print("❌ fetchTasks error: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Add Task
    func addTask(_ task: UserTask) async {
        do {
            // Normalize dates before sending to Supabase
            let taskToInsert = normalizeTaskDates(task)
            print("📝 Inserting task: \(taskToInsert.title) | scheduledDate=\(String(describing: taskToInsert.scheduledDate)) | endDate=\(String(describing: taskToInsert.endDate))")
            
            // Insert into Supabase
            let inserted: UserTask = try await client
                .from("tasks")
                .insert(taskToInsert)
                .select()
                .single()
                .execute()
                .value
            
            // Normalize the decoded dates; fall back to original if Supabase decode lost them
            var finalTask = inserted
            if finalTask.scheduledDate == nil && task.scheduledDate != nil {
                finalTask.scheduledDate = Calendar.current.startOfDay(for: task.scheduledDate!)
                print("⚠️ Supabase lost scheduledDate, restored from original: \(String(describing: finalTask.scheduledDate))")
            } else {
                finalTask = normalizeTaskDates(finalTask)
            }
            if finalTask.endDate == nil && task.endDate != nil {
                finalTask.endDate = Calendar.current.startOfDay(for: task.endDate!)
                print("⚠️ Supabase lost endDate, restored from original: \(String(describing: finalTask.endDate))")
            }
            
            // Add to local array — @MainActor ensures UI updates
            tasks.insert(finalTask, at: 0)
            print("✅ Task inserted: \(finalTask.title) | scheduledDate=\(String(describing: finalTask.scheduledDate)) | endDate=\(String(describing: finalTask.endDate))")
            
            // Schedule local notification if needed
            if task.scheduledTime != nil {
                await NotificationManager.shared.scheduleNotification(for: finalTask)
            }
        } catch {
            errorMessage = "Failed to add task: \(error.localizedDescription)"
            print("❌ addTask error: \(error)")
        }
    }
    
    // MARK: - Add Tasks Batch
    func addTasksBatch(_ taskItems: [UserTask]) async {
        for task in taskItems {
            await addTask(task)
        }
    }
    
    // MARK: - Update Task
    func updateTask(_ task: UserTask) async {
        do {
            try await client
                .from("tasks")
                .update(task)
                .eq("id", value: task.id.uuidString)
                .execute()
            
            // Update locally with normalized dates
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                await NotificationManager.shared.cancelNotification(for: task.id)
                tasks[index] = normalizeTaskDates(task)
                if task.scheduledTime != nil {
                    await NotificationManager.shared.scheduleNotification(for: task)
                }
            }
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Delete Task
    func deleteTask(_ task: UserTask) async {
        do {
            try await client
                .from("tasks")
                .delete()
                .eq("id", value: task.id.uuidString)
                .execute()
            
            await NotificationManager.shared.cancelNotification(for: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Toggle Completion (legacy — non-repeating tasks)
    func toggleCompletion(for task: UserTask) async {
        // For repeating tasks, use the per-day version with today's date
        if task.repeatType != .never {
            await toggleCompletion(for: task, on: Date())
            return
        }
        var updated = task
        updated.isCompleted.toggle()
        await updateTask(updated)
        if updated.isCompleted, let userId = UserStore.shared.currentUser?.id {
            await ProgressStore.shared.incrementTasksCompleted(userId: userId)
        }
    }
    
    // MARK: - Per-Day Completion (for repeating tasks)
    
    /// Check if a task is completed on a specific date.
    /// For non-repeating tasks, uses the `isCompleted` flag.
    /// For repeating tasks, checks the `taskCompletions` dictionary.
    func isTaskCompleted(_ task: UserTask, on date: Date) -> Bool {
        if task.repeatType == .never {
            return task.isCompleted
        }
        let dateKey = Self.dateKey(from: date)
        return taskCompletions[task.id]?.contains(dateKey) ?? false
    }
    
    /// Toggle completion for a task on a specific date.
    /// For repeating tasks, inserts/deletes from `task_completions` table.
    /// For non-repeating tasks, falls back to the old toggle.
    func toggleCompletion(for task: UserTask, on date: Date) async {
        if task.repeatType == .never {
            await toggleCompletion(for: task)
            return
        }
        
        let dateKey = Self.dateKey(from: date)
        let isCurrentlyCompleted = taskCompletions[task.id]?.contains(dateKey) ?? false
        
        if isCurrentlyCompleted {
            // Remove completion
            do {
                try await client
                    .from("task_completions")
                    .delete()
                    .eq("task_id", value: task.id.uuidString)
                    .eq("completed_date", value: dateKey)
                    .execute()
                
                taskCompletions[task.id]?.remove(dateKey)
                print("✅ Removed completion for \(task.title) on \(dateKey)")
            } catch {
                errorMessage = "Failed to update completion: \(error.localizedDescription)"
                print("❌ Remove completion error: \(error)")
            }
        } else {
            // Add completion
            do {
                let completion = TaskCompletion(
                    taskId: task.id,
                    completedDate: dateKey
                )
                try await client
                    .from("task_completions")
                    .insert(completion)
                    .execute()
                
                if taskCompletions[task.id] == nil {
                    taskCompletions[task.id] = []
                }
                taskCompletions[task.id]?.insert(dateKey)
                print("✅ Added completion for \(task.title) on \(dateKey)")
                
                // Increment progress
                if let userId = UserStore.shared.currentUser?.id {
                    await ProgressStore.shared.incrementTasksCompleted(userId: userId)
                }
            } catch {
                errorMessage = "Failed to update completion: \(error.localizedDescription)"
                print("❌ Add completion error: \(error)")
            }
        }
    }
    
    // MARK: - Fetch Task Completions
    func fetchTaskCompletions(userId: UUID) async {
        do {
            let fetched: [TaskCompletion] = try await client
                .from("task_completions")
                .select()
                .in("task_id", values: tasks.map { $0.id.uuidString })
                .execute()
                .value
            
            var completions: [UUID: Set<String>] = [:]
            for c in fetched {
                if completions[c.taskId] == nil {
                    completions[c.taskId] = []
                }
                completions[c.taskId]?.insert(c.completedDate)
            }
            taskCompletions = completions
            print("✅ Fetched \(fetched.count) task completions")
        } catch {
            print("❌ fetchTaskCompletions error: \(error)")
        }
    }
    
    // MARK: - Date Key Helper
    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    static func dateKey(from date: Date) -> String {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        return dateKeyFormatter.string(from: day)
    }
    
    // MARK: - Categories
    func fetchCategories() async {
        isLoading = true
        do {
            let fetched: [TaskCategory] = try await client
                .from("task_categories")
                .select()
                .execute()
                .value
            categories = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addCategory(_ category: TaskCategory) async {
        do {
            let inserted: TaskCategory = try await client
                .from("task_categories")
                .insert(category)
                .select()
                .single()
                .execute()
                .value
            categories.append(inserted)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateCategory(_ category: TaskCategory) async {
        do {
            try await client
                .from("task_categories")
                .update(category)
                .eq("id", value: category.id.uuidString)
                .execute()
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index] = category
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteCategory(_ category: TaskCategory) async {
        do {
            try await client
                .from("task_categories")
                .delete()
                .eq("id", value: category.id.uuidString)
                .execute()
            categories.removeAll { $0.id == category.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

