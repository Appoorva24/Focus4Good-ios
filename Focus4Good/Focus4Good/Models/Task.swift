import Foundation

// MARK: - TaskCategory
struct TaskCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var color: String
}

// MARK: - UserTask
struct UserTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var categoryId: UUID?
    var title: String
    var scheduledDate: Date?
    var scheduledTime: Date?
    var repeatType: RepeatType
    var priority: Priority
    var isCompleted: Bool
    var estimatedDuration: Int?
    var createdAt: Date

    enum RepeatType: String, Codable, CaseIterable {
        case never
        case daily
        case weekdays
        case weekends
        case weekly
        case fortnightly
        case monthly
        case every3Months = "every_3_months"
        case every6Months = "every_6_months"
        case yearly
        case custom
    }

    enum Priority: String, Codable, CaseIterable {
        case none
        case low
        case medium
        case high
    }
}
