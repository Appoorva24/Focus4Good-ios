import Foundation
import Supabase

@MainActor
@Observable
class CalmCentreStore {

    // MARK: - State
    var breathingSessions: [BreathingSession] = []
    var jpmrSessions: [JpmrSession] = []
    var guidedMeditationSessions: [GuidedMeditationSession] = []
    var asmrSounds: [AsmrSound] = []
    var favouriteAsmrSoundIds: Set<UUID> = []
    var brainDumpFolders: [BrainDumpFolder] = []
    var brainDumpEntries: [BrainDumpEntry] = []
    var activeAsmrSound: AsmrSound?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed

    //filter karke favourites nikalta hai
    var favouriteAsmrSounds: [AsmrSound] { asmrSounds.filter { favouriteAsmrSoundIds.contains($0.id) } }

    //sound ko category wise group karta hai
    var asmrSoundsByCategory: [String: [AsmrSound]] { Dictionary(grouping: asmrSounds, by: { $0.category }) }

    //latest notes ko upar rakhta hai
    var recentBrainDumpEntries: [BrainDumpEntry] { brainDumpEntries.sorted { $0.createdAt > $1.createdAt } }

    var totalCalmMinutesToday: Int {
        let cal = Calendar.current//current date system
        let b = breathingSessions.filter { cal.isDateInToday($0.completedAt) }.reduce(0) { $0 + $1.durationSeconds / 60 }//aaj ke breathing sessions ko minutes mein convert
        let j = jpmrSessions.filter { cal.isDateInToday($0.completedAt) }.reduce(0) { $0 + $1.durationSeconds / 60 }
        let m = guidedMeditationSessions.filter { cal.isDateInToday($0.completedAt) }.reduce(0) { $0 + $1.durationSeconds / 60 }
        return b + j + m
    }

    func brainDumpEntries(in folder: BrainDumpFolder) -> [BrainDumpEntry] {
        brainDumpEntries.filter { $0.folderId == folder.id }
    }

    static let shared = CalmCentreStore()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    init() {}

    // MARK: - Clear (called on sign-out)
    func clearData() {
        breathingSessions = []
        jpmrSessions = []
        guidedMeditationSessions = []
        asmrSounds = []
        favouriteAsmrSoundIds = []
        brainDumpFolders = []
        brainDumpEntries = []
        activeAsmrSound = nil
    }

    // MARK: - Fetch from Supabase
    func fetchBreathingSessions(userId: UUID) async {
        isLoading = true
        do {
            let fetched: [BreathingSession] = try await client
                .from("breathing_sessions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("completed_at", ascending: false)
                .execute()
                .value
            breathingSessions = fetched
        } catch {
            errorMessage = "Failed to load breathing sessions: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchJpmrSessions(userId: UUID) async {
        isLoading = true
        do {
            let fetched: [JpmrSession] = try await client
                .from("jpmr_sessions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("completed_at", ascending: false)
                .execute()
                .value
            jpmrSessions = fetched
        } catch {
            errorMessage = "Failed to load JPMR sessions: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchGuidedMeditationSessions(userId: UUID) async {
        isLoading = true
        do {
            let fetched: [GuidedMeditationSession] = try await client
                .from("guided_meditation_sessions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("completed_at", ascending: false)
                .execute()
                .value
            guidedMeditationSessions = fetched
        } catch {
            errorMessage = "Failed to load meditation sessions: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchAsmrSounds() async {
        isLoading = true
        do {
            let fetched: [AsmrSound] = try await client
                .from("asmr_sounds")
                .select()
                .execute()
                .value
            asmrSounds = fetched
        } catch {
            errorMessage = "Failed to load ASMR sounds: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchFavouriteAsmrSounds(userId: UUID) async {
        do {
            let fetched: [AsmrFavourite] = try await client
                .from("asmr_favourites")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            favouriteAsmrSoundIds = Set(fetched.map { $0.soundId })
        } catch {
            errorMessage = "Failed to load favourites: \(error.localizedDescription)"
        }
    }

    func fetchBrainDumpFolders(userId: UUID) async {
        isLoading = true
        do {
            let fetched: [BrainDumpFolder] = try await client
                .from("brain_dump_folders")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            brainDumpFolders = fetched
        } catch {
            errorMessage = "Failed to load folders: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchBrainDumpEntries(userId: UUID) async {
        isLoading = true
        do {
            let fetched: [BrainDumpEntry] = try await client
                .from("brain_dump_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            brainDumpEntries = fetched
        } catch {
            errorMessage = "Failed to load entries: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Log Sessions
    func logBreathingSession(userId: UUID, cyclesCompleted: Int, durationSeconds: Int) async {
        let points = cyclesCompleted * 10
        let session = BreathingSession(
            userId: userId, cyclesCompleted: cyclesCompleted,
            durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date()
        )
        do {
            let inserted: BreathingSession = try await client
                .from("breathing_sessions")
                .insert(session)
                .select().single().execute().value
            breathingSessions.insert(inserted, at: 0)
        } catch {
            errorMessage = "Failed to log breathing session: \(error.localizedDescription)"
        }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func logJpmrSession(userId: UUID, durationSeconds: Int, pointsOverride: Int? = nil) async {
        let points = pointsOverride ?? 30
        let session = JpmrSession(
            userId: userId, durationSeconds: durationSeconds,
            pointsEarned: points, completedAt: Date()
        )
        do {
            let inserted: JpmrSession = try await client
                .from("jpmr_sessions")
                .insert(session)
                .select().single().execute().value
            jpmrSessions.insert(inserted, at: 0)
        } catch {
            errorMessage = "Failed to log JPMR session: \(error.localizedDescription)"
        }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func logGuidedMeditationSession(userId: UUID, meditationName: String, durationSeconds: Int) async {
        let points = 50
        let session = GuidedMeditationSession(
            userId: userId, meditationName: meditationName,
            durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date()
        )
        do {
            let inserted: GuidedMeditationSession = try await client
                .from("guided_meditation_sessions")
                .insert(session)
                .select().single().execute().value
            guidedMeditationSessions.insert(inserted, at: 0)
        } catch {
            errorMessage = "Failed to log meditation session: \(error.localizedDescription)"
        }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    // MARK: - ASMR
    func playAsmrSound(_ sound: AsmrSound) { activeAsmrSound = sound }
    func stopAsmrSound() { activeAsmrSound = nil }

    func toggleAsmrFavourite(soundId: UUID, userId: UUID) async {
        if favouriteAsmrSoundIds.contains(soundId) {
            // Remove favourite
            favouriteAsmrSoundIds.remove(soundId)
            do {
                try await client
                    .from("asmr_favourites")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("sound_id", value: soundId.uuidString)
                    .execute()
            } catch {
                // Revert on failure
                favouriteAsmrSoundIds.insert(soundId)
                errorMessage = error.localizedDescription
            }
        } else {
            // Add favourite
            favouriteAsmrSoundIds.insert(soundId)
            let fav = AsmrFavourite(userId: userId, soundId: soundId)
            do {
                try await client
                    .from("asmr_favourites")
                    .insert(fav)
                    .execute()
            } catch {
                // Revert on failure
                favouriteAsmrSoundIds.remove(soundId)
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Brain Dump Folders
    func addBrainDumpFolder(name: String, userId: UUID) async {
        let folder = BrainDumpFolder(userId: userId, name: name, entryCount: 0)
        do {
            let inserted: BrainDumpFolder = try await client
                .from("brain_dump_folders")
                .insert(folder)
                .select().single().execute().value
            brainDumpFolders.append(inserted)
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }

    func updateBrainDumpFolder(_ folder: BrainDumpFolder) async {
        do {
            try await client
                .from("brain_dump_folders")
                .update(folder)
                .eq("id", value: folder.id.uuidString)
                .execute()
            if let index = brainDumpFolders.firstIndex(where: { $0.id == folder.id }) {
                brainDumpFolders[index] = folder
            }
        } catch {
            errorMessage = "Failed to update folder: \(error.localizedDescription)"
        }
    }

    func deleteBrainDumpFolder(_ folder: BrainDumpFolder) async {
        do {
            try await client
                .from("brain_dump_folders")
                .delete()
                .eq("id", value: folder.id.uuidString)
                .execute()
            brainDumpFolders.removeAll { $0.id == folder.id }
            // Orphan entries (set folderId to nil) — handled by DB ON DELETE SET NULL
            for i in brainDumpEntries.indices where brainDumpEntries[i].folderId == folder.id {
                brainDumpEntries[i].folderId = nil
            }
        } catch {
            errorMessage = "Failed to delete folder: \(error.localizedDescription)"
        }
    }

    // MARK: - Brain Dump Entries
    func addBrainDumpEntry(content: String, userId: UUID, folderId: UUID? = nil) async {
        let points = 10
        let entry = BrainDumpEntry(userId: userId, folderId: folderId, content: content, pointsEarned: points, createdAt: Date())
        do {
            let inserted: BrainDumpEntry = try await client
                .from("brain_dump_entries")
                .insert(entry)
                .select().single().execute().value
            brainDumpEntries.insert(inserted, at: 0)
            if let folderId, let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
                brainDumpFolders[index].entryCount += 1
            }
        } catch {
            errorMessage = "Failed to create entry: \(error.localizedDescription)"
        }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func updateBrainDumpEntry(_ entry: BrainDumpEntry) async {
        do {
            try await client
                .from("brain_dump_entries")
                .update(entry)
                .eq("id", value: entry.id.uuidString)
                .execute()
            if let index = brainDumpEntries.firstIndex(where: { $0.id == entry.id }) {
                brainDumpEntries[index] = entry
            }
        } catch {
            errorMessage = "Failed to update entry: \(error.localizedDescription)"
        }
    }

    func deleteBrainDumpEntry(_ entry: BrainDumpEntry) async {
        do {
            try await client
                .from("brain_dump_entries")
                .delete()
                .eq("id", value: entry.id.uuidString)
                .execute()
            brainDumpEntries.removeAll { $0.id == entry.id }
            if let folderId = entry.folderId, let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
                brainDumpFolders[index].entryCount = max(0, brainDumpFolders[index].entryCount - 1)
            }
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }
}
