import Foundation

@Observable
class TaskStore {

    // MARK: - State
    var tasks: [UserTask] = []
    var categories: [TaskCategory] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
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
    private init() {}

    // MARK: - Tasks
    func fetchTasks(userId: UUID) async {
        isLoading = true
        isLoading = false
    }

    func addTask(_ task: UserTask) async {
        tasks.append(task)

        // Schedule notification if task has time
        if task.scheduledTime != nil {
            await NotificationManager.shared.scheduleNotification(for: task)
            print("✅ Task added with notification: \(task.title)")
        } else {
            print("✅ Task added without notification: \(task.title)")
        }
    }

    func updateTask(_ task: UserTask) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Cancel old notification
            await NotificationManager.shared.cancelNotification(for: task.id)

            // Update task
            tasks[index] = task

            // Schedule new notification if task has time
            if task.scheduledTime != nil {
                await NotificationManager.shared.scheduleNotification(for: task)
                print("✅ Task updated with new notification: \(task.title)")
            } else {
                print("✅ Task updated without notification: \(task.title)")
            }
        }
    }

    func deleteTask(_ task: UserTask) async {
        // Cancel notification first
        await NotificationManager.shared.cancelNotification(for: task.id)

        // Remove task
        tasks.removeAll { $0.id == task.id }

        print("✅ Task deleted and notification cancelled: \(task.title)")
    }

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
        isLoading = false
    }

    func addCategory(_ category: TaskCategory) async { categories.append(category) }

    func updateCategory(_ category: TaskCategory) async {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }

    func deleteCategory(_ category: TaskCategory) async {
        categories.removeAll { $0.id == category.id }
    }
}
