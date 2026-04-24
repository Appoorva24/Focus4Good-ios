import Foundation

struct TaskCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var color: String
}

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
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case categoryId = "category_id"
        case title
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case repeatType = "repeat_type"
        case priority
        case isCompleted = "is_completed"
        case estimatedDuration = "estimated_duration"
        case createdAt = "created_at"
    }
    
    enum RepeatType: String, Codable, CaseIterable {
        case never, daily, weekdays, weekends, weekly
        case fortnightly, monthly
        case every3Months = "every_3_months"
        case every6Months = "every_6_months"
        case yearly, custom
    }
    
    enum Priority: String, Codable, CaseIterable {
        case none, low, medium, high
    }
}

