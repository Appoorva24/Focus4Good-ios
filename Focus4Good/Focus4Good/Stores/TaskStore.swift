import Foundation
import Combine

@MainActor
final class TaskStore: ObservableObject {

    // MARK: - State
    @Published var tasks: [UserTask] = []
    @Published var categories: [TaskCategory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

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
    private init() {
        tasks = DummyData.tasks
    }

    // MARK: - Tasks
    func fetchTasks(userId: UUID) async {
        isLoading = true
        isLoading = false
    }

    func addTask(_ task: UserTask) async {
        tasks.append(task)
    }

    func updateTask(_ task: UserTask) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }

    func deleteTask(_ task: UserTask) async {
        tasks.removeAll { $0.id == task.id }
    }

    func toggleCompletion(for task: UserTask) async {
        var updated = task
        updated.isCompleted.toggle()
        await updateTask(updated)
        if updated.isCompleted {
            guard let userId = UserStore.shared.currentUser?.id else { return }
            await ProgressStore.shared.incrementTasksCompleted(userId: userId)
        }
    }

    // MARK: - Categories
    func fetchCategories() async {
        isLoading = true
        isLoading = false
    }

    func addCategory(_ category: TaskCategory) async {
        categories.append(category)
    }

    func updateCategory(_ category: TaskCategory) async {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }

    func deleteCategory(_ category: TaskCategory) async {
        categories.removeAll { $0.id == category.id }
    }
}
