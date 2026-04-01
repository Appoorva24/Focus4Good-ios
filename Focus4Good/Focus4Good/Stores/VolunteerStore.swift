import Foundation

@Observable
class VolunteerStore {

    // MARK: - State
    var ngos: [NGO] = []
    var volunteerEvents: [VolunteerEvent] = []
    var volunteerRegistrations: [VolunteerRegistration] = []

    // MARK: - Computed
    func events(for ngo: NGO) -> [VolunteerEvent] {
        volunteerEvents
            .filter { $0.ngoId == ngo.id }
            .sorted { $0.eventDate < $1.eventDate }
    }

    func isRegistered(ngoId: UUID, userId: UUID) -> Bool {
        volunteerRegistrations.contains { $0.ngoId == ngoId && $0.userId == userId }
    }

    // MARK: - Init
    static let shared = VolunteerStore()
    private init() {
        ngos = DummyData.ngos
        for ngo in ngos {
            volunteerEvents.append(contentsOf: DummyData.volunteerEvents(for: ngo.id))
        }
    }

    // MARK: - Register
    func registerForNGO(
        userId: UUID,
        ngoId: UUID,
        fullName: String,
        email: String,
        phone: String,
        pastExperience: String
    ) async {
        guard !isRegistered(ngoId: ngoId, userId: userId) else { return }
        volunteerRegistrations.append(
            VolunteerRegistration(
                userId: userId,
                ngoId: ngoId,
                fullName: fullName,
                email: email,
                phone: phone,
                pastExperience: pastExperience,
                registeredAt: Date()
            )
        )
    }
}
