import Foundation
import Combine

@MainActor
final class VolunteerStore: ObservableObject {

    // MARK: - State
    @Published var ngos: [NGO] = []
    @Published var volunteerEvents: [VolunteerEvent] = []
    @Published var volunteerRegistrations: [VolunteerRegistration] = []
    @Published var eventItineraries: [EventItinerary] = []
    @Published var eventAttendances: [EventAttendance] = []
    @Published var selectedNGO: NGO?
    @Published var selectedEvent: VolunteerEvent?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed
    func events(for ngo: NGO) -> [VolunteerEvent] {
        volunteerEvents.filter { $0.ngoId == ngo.id }.sorted { $0.eventDate < $1.eventDate }
    }

    func itinerary(for event: VolunteerEvent) -> [EventItinerary] {
        eventItineraries.filter { $0.eventId == event.id }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func upcomingEvents() -> [VolunteerEvent] {
        volunteerEvents.filter { $0.eventDate >= Date() }.sorted { $0.eventDate < $1.eventDate }
    }

    func isRegistered(ngoId: UUID, userId: UUID) -> Bool {
        volunteerRegistrations.contains { $0.ngoId == ngoId && $0.userId == userId }
    }

    func isAttending(eventId: UUID, userId: UUID) -> Bool {
        eventAttendances.contains { $0.eventId == eventId && $0.userId == userId }
    }

    func userRegistrations(userId: UUID) -> [VolunteerRegistration] { volunteerRegistrations.filter { $0.userId == userId } }
    func userAttendances(userId: UUID) -> [EventAttendance] { eventAttendances.filter { $0.userId == userId } }

    static let shared = VolunteerStore()
    private init() {}

    // MARK: - NGOs
    func fetchNGOs() async {
        isLoading = true
        do { isLoading = false }
    }

    // MARK: - Events
    func fetchEvents() async {
        isLoading = true
        do { isLoading = false }
    }

    func fetchEvents(for ngoId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func fetchItinerary(for eventId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    // MARK: - Registrations
    func registerForNGO(userId: UUID, ngoId: UUID, fullName: String, email: String, phone: String, emergencyContact: String, availableDays: String, pastExperience: String) async {
        guard !isRegistered(ngoId: ngoId, userId: userId) else { return }
        let registration = VolunteerRegistration(
            userId: userId,
            ngoId: ngoId,
            fullName: fullName,
            email: email,
            phone: phone,
            emergencyContact: emergencyContact,
            availableDays: availableDays,
            pastExperience: pastExperience,
            registeredAt: Date()
        )
        volunteerRegistrations.append(registration)
    }

    func fetchRegistrations(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    // MARK: - Attendance
    func confirmAttendance(userId: UUID, eventId: UUID, focusPointsCommitted: Int) async {
        guard !isAttending(eventId: eventId, userId: userId) else { return }
        let attendance = EventAttendance(
            userId: userId,
            eventId: eventId,
            focusPointsCommitted: focusPointsCommitted,
            confirmedAt: Date()
        )
        eventAttendances.append(attendance)
        if let index = volunteerEvents.firstIndex(where: { $0.id == eventId }) {
            volunteerEvents[index].participantCount += 1
        }
    }

    func cancelAttendance(userId: UUID, eventId: UUID) async {
        eventAttendances.removeAll { $0.eventId == eventId && $0.userId == userId }
        if let index = volunteerEvents.firstIndex(where: { $0.id == eventId }) {
            volunteerEvents[index].participantCount = max(0, volunteerEvents[index].participantCount - 1)
        }
    }

    func fetchAttendances(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }
}
