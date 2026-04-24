import Foundation

// MARK: - NGO
struct NGO: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var location: String
    var mission: String
    var founderName: String
    var founderPhone: String
    var imageName: String
    var studentCount: Int
    var yearsActive: Int
    var projectCount: Int
    var isVerified: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case mission
        case founderName = "founder_name"
        case founderPhone = "founder_phone"
        case imageName = "image_name"
        case studentCount = "student_count"
        case yearsActive = "years_active"
        case projectCount = "project_count"
        case isVerified = "is_verified"
    }
}

// MARK: - VolunteerEvent
struct VolunteerEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ngoId: UUID
    var title: String
    var location: String
    var eventDate: Date
    var participantCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case ngoId = "ngo_id"
        case title
        case location
        case eventDate = "event_date"
        case participantCount = "participant_count"
    }
}

// MARK: - VolunteerRegistration
struct VolunteerRegistration: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var ngoId: UUID
    var fullName: String
    var email: String
    var phone: String
    var pastExperience: String
    var registeredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ngoId = "ngo_id"
        case fullName = "full_name"
        case email
        case phone
        case pastExperience = "past_experience"
        case registeredAt = "registered_at"
    }
}
