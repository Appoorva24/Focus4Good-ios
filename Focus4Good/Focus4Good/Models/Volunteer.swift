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
}

// MARK: - VolunteerEvent
struct VolunteerEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ngoId: UUID
    var title: String
    var location: String
    var eventDate: Date
    var participantCount: Int
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
}
