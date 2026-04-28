import Foundation
import Supabase

@MainActor
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

    // MARK: - Clear (called on sign-out)
    func clearData() {
        ngos = []
        volunteerEvents = []
        volunteerRegistrations = []
    }

    // MARK: - Fetch from Supabase (with dummy fallback)
    func fetchNGOs() async {
        isLoading = true
        do {
            let fetched: [NGO] = try await client
                .from("ngos")
                .select()
                .execute()
                .value
            ngos = fetched.isEmpty ? Self.dummyNGOs : fetched
        } catch {
            // Fallback to dummy data when Supabase unreachable or table empty
            ngos = Self.dummyNGOs
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
            // If DB has no events, seed from dummy events keyed to current NGO IDs
            if fetched.isEmpty {
                volunteerEvents = ngos.flatMap { Self.dummyEvents(for: $0.id) }
            } else {
                volunteerEvents = fetched
            }
        } catch {
            volunteerEvents = ngos.flatMap { Self.dummyEvents(for: $0.id) }
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
            // Still store locally so UI reflects registration even if DB fails
            volunteerRegistrations.append(reg)
            errorMessage = "Registration saved locally. Sync may retry later."
        }
    }

    // MARK: - Static Dummy Data (2 NGOs, fully featured)

    /// Fixed IDs so events can reference them deterministically
    static let ngo1ID = UUID(uuidString: "a1000000-0000-0000-0000-000000000001")!
    static let ngo2ID = UUID(uuidString: "a2000000-0000-0000-0000-000000000002")!

    static let dummyNGOs: [NGO] = [
        NGO(
            id: ngo1ID,
            name: "Teach For India",
            location: "Mumbai, Maharashtra",
            mission: "Eliminating educational inequity by placing passionate graduates as full-time teachers in low-income schools across India — building a movement of leaders committed to a day when all children attain an excellent education.",
            founderName: "Shaheen Mistri",
            founderPhone: "+91-22-6656-0200",
            imageName: "ngo",
            studentCount: 38000,
            yearsActive: 15,
            projectCount: 12,
            isVerified: true
        ),
        NGO(
            id: ngo2ID,
            name: "Pratham Education Foundation",
            location: "New Delhi, Delhi",
            mission: "Improving quality of education for underprivileged children across India through innovative, scalable teaching methods that reach millions of children directly in their villages and schools.",
            founderName: "Madhav Chavan",
            founderPhone: "+91-11-4141-0000",
            imageName: "ngo",
            studentCount: 75000,
            yearsActive: 28,
            projectCount: 20,
            isVerified: true
        )
    ]

    static func dummyEvents(for ngoId: UUID) -> [VolunteerEvent] {
        if ngoId == ngo1ID {
            return [
                VolunteerEvent(
                    id: UUID(),
                    ngoId: ngoId,
                    title: "Teaching Drive — South Delhi",
                    location: "South Delhi Community Centre",
                    eventDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                    participantCount: 24
                ),
                VolunteerEvent(
                    id: UUID(),
                    ngoId: ngoId,
                    title: "Literacy Camp — Dharavi",
                    location: "Dharavi, Mumbai",
                    eventDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
                    participantCount: 50
                )
            ]
        } else {
            return [
                VolunteerEvent(
                    id: UUID(),
                    ngoId: ngoId,
                    title: "Community Awareness Walk",
                    location: "Connaught Place, Delhi",
                    eventDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                    participantCount: 38
                ),
                VolunteerEvent(
                    id: UUID(),
                    ngoId: ngoId,
                    title: "Rural Education Outreach",
                    location: "Meerut, Uttar Pradesh",
                    eventDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                    participantCount: 60
                )
            ]
        }
    }
}

