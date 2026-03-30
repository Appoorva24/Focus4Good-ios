import Foundation

// MARK: - NGO
struct NGO: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var location: String
    var mission: String
    var founderName: String
    var founderPhone: String
    var imageUrl: String?
    var studentCount: Int
    var yearsActive: Int
    var projectCount: Int
    var isVerified: Bool
}

// MARK: - VolunteerEvent
struct VolunteerEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ngoId: UUID
    var title: String
    var description: String
    var eventType: String
    var location: String
    var eventDate: Date
    var startTime: Date
    var endTime: Date
    var imageUrl: String?
    var participantCount: Int
    var creatorId: UUID
}

// MARK: - VolunteerRegistration
struct VolunteerRegistration: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var ngoId: UUID
    var fullName: String
    var email: String
    var phone: String
    var emergencyContact: String
    var availableDays: String
    var pastExperience: String
    var registeredAt: Date
}

// MARK: - EventItinerary
struct EventItinerary: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var eventId: UUID
    var time: Date
    var activity: String
    var sortOrder: Int
}

// MARK: - EventAttendance
struct EventAttendance: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var eventId: UUID
    var focusPointsCommitted: Int
    var confirmedAt: Date
}
