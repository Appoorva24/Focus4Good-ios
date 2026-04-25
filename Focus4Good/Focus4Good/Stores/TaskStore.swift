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
    
    // MARK: - Computed (UNCHANGED — these still work!)
    var todaysTasks: [UserTask] {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { task in
            guard let date = task.scheduledDate else { return false }
            return Calendar.current.isDate(date, inSameDayAs: today)
        }
    }
    var completedTasks: [UserTask] { tasks.filter { $0.isCompleted } }
    var pendingTasks: [UserTask] { tasks.filter { !$0.isCompleted } }
    func tasks(for category: TaskCategory) -> [UserTask] {
        tasks.filter { $0.categoryId == category.id }
    }
    
    static let shared = TaskStore()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    init() {}
    
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
            tasks = fetched
            print("✅ Fetched \(fetched.count) tasks")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            print("❌ fetchTasks error: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Add Task
    func addTask(_ task: UserTask) async {
        do {
            print("📝 Inserting task: \(task.title) for user: \(task.userId)")
            
            // Insert into Supabase
            let inserted: UserTask = try await client
                .from("tasks")
                .insert(task)
                .select()
                .single()
                .execute()
                .value
            
            // Add to local array — @MainActor ensures UI updates
            tasks.insert(inserted, at: 0)
            print("✅ Task inserted successfully: \(inserted.title) (id: \(inserted.id))")
            
            // Schedule local notification if needed
            if task.scheduledTime != nil {
                await NotificationManager.shared.scheduleNotification(for: inserted)
            }
        } catch {
            errorMessage = "Failed to add task: \(error.localizedDescription)"
            print("❌ addTask error: \(error)")
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
            
            // Update locally
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                await NotificationManager.shared.cancelNotification(for: task.id)
                tasks[index] = task
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
    
    // MARK: - Toggle Completion
    func toggleCompletion(for task: UserTask) async {
        var updated = task
        updated.isCompleted.toggle()
        await updateTask(updated)
        if updated.isCompleted, let userId = UserStore.shared.currentUser?.id {
            await ProgressStore.shared.incrementTasksCompleted(userId: userId)
        }
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

