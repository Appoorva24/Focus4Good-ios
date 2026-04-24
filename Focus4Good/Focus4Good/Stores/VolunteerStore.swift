import Foundation
import Supabase

@Observable
class VolunteerStore {

    // MARK: - State
    var ngos: [NGO] = []
    var volunteerEvents: [VolunteerEvent] = []
    var volunteerRegistrations: [VolunteerRegistration] = []
    var isLoading = false
    var errorMessage: String?

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
    private var client: SupabaseClient { SupabaseManager.shared.client }
    init() {}

    // MARK: - Fetch from Supabase
    func fetchNGOs() async {
        isLoading = true
        do {
            let fetched: [NGO] = try await client
                .from("ngos")
                .select()
                .execute()
                .value
            ngos = fetched
        } catch {
            errorMessage = "Failed to load NGOs: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchVolunteerEvents() async {
        isLoading = true
        do {
            let fetched: [VolunteerEvent] = try await client
                .from("volunteer_events")
                .select()
                .order("event_date", ascending: true)
                .execute()
                .value
            volunteerEvents = fetched
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchRegistrations(userId: UUID) async {
        do {
            let fetched: [VolunteerRegistration] = try await client
                .from("volunteer_registrations")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            volunteerRegistrations = fetched
        } catch {
            errorMessage = "Failed to load registrations: \(error.localizedDescription)"
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
        let reg = VolunteerRegistration(
            userId: userId,
            ngoId: ngoId,
            fullName: fullName,
            email: email,
            phone: phone,
            pastExperience: pastExperience,
            registeredAt: Date()
        )
        do {
            let inserted: VolunteerRegistration = try await client
                .from("volunteer_registrations")
                .insert(reg)
                .select()
                .single()
                .execute()
                .value
            volunteerRegistrations.append(inserted)
        } catch {
            errorMessage = "Failed to register: \(error.localizedDescription)"
        }
    }
}
