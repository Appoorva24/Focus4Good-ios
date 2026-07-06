import Foundation
import Supabase

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
    var isASMRPlayerPresented = false
    var showGlobalASMRPlayer = false
    var jpmrVideoUrl: String?
    var isLoadingVideo = false
    var videoErrorMessage: String?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
    var favouriteAsmrSounds: [AsmrSound] { asmrSounds.filter { favouriteAsmrSoundIds.contains($0.id) } }
    var asmrSoundsByCategory: [String: [AsmrSound]] { Dictionary(grouping: asmrSounds, by: { $0.category }) }
    var recentBrainDumpEntries: [BrainDumpEntry] { brainDumpEntries.sorted { $0.createdAt > $1.createdAt } }

    var totalCalmMinutesToday: Int {
        let cal = Calendar.current
        let b = breathingSessions.filter { cal.isDateInToday($0.completedAt) }.reduce(0) { $0 + $1.durationSeconds / 60 }
        let j = jpmrSessions.filter { cal.isDateInToday($0.completedAt) }.reduce(0) { $0 + $1.durationSeconds / 60 }
        let m = guidedMeditationSessions.filter { cal.isDateInToday($0.completedAt) }.reduce(0) { $0 + $1.durationSeconds / 60 }
        return b + j + m
    }

    func brainDumpEntries(in folder: BrainDumpFolder) -> [BrainDumpEntry] {
        brainDumpEntries.filter { $0.folderId == folder.id }
    }

    static let shared = CalmCentreStore()
    private init() {}

    // MARK: - Fetch

    func fetchJpmrVideoUrl() async {
        isLoadingVideo = true
        defer { isLoadingVideo = false }
        do {
            let videos: [JpmrVideo] = try await SupabaseManager.shared.client
                .from("jpmr_videos")
                .select()
                .limit(1)
                .execute()
                .value
            jpmrVideoUrl = videos.first?.videoUrl
            videoErrorMessage = nil
        } catch {
            print("Failed to fetch JPMR video URL: \(error)")
            videoErrorMessage = error.localizedDescription
        }
    }

    func fetchBreathingSessions(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [BreathingSession] = try await SupabaseManager.shared.client
                .from("breathing_sessions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            breathingSessions = fetched
        } catch { print("Fetch error: \(error)") }
    }

    func fetchJpmrSessions(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [JpmrSession] = try await SupabaseManager.shared.client
                .from("jpmr_sessions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            jpmrSessions = fetched
        } catch { print("Fetch error: \(error)") }
    }

    func fetchGuidedMeditationSessions(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [GuidedMeditationSession] = try await SupabaseManager.shared.client
                .from("guided_meditation_sessions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            guidedMeditationSessions = fetched
        } catch { print("Fetch error: \(error)") }
    }

    func fetchAsmrSounds() async {
        // Sounds are hardcoded in ASMRData.swift, no need to fetch unless moved to DB.
    }

    func fetchFavouriteAsmrSounds(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [UserFavouriteAsmrSound] = try await SupabaseManager.shared.client
                .from("user_favourite_asmr_sounds")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            favouriteAsmrSoundIds = Set(fetched.map { $0.soundId })
        } catch { print("Fetch error: \(error)") }
    }

    func fetchBrainDumpFolders(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [BrainDumpFolder] = try await SupabaseManager.shared.client
                .from("brain_dump_folders")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            brainDumpFolders = fetched
        } catch { print("Fetch error: \(error)") }
    }

    func fetchBrainDumpEntries(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched: [BrainDumpEntry] = try await SupabaseManager.shared.client
                .from("brain_dump_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            brainDumpEntries = fetched
        } catch { print("Fetch error: \(error)") }
    }

    // MARK: - Log Sessions
    func logBreathingSession(userId: UUID, cyclesCompleted: Int, durationSeconds: Int) async {
        let points = cyclesCompleted * 10
        let session = BreathingSession(userId: userId, cyclesCompleted: cyclesCompleted, durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date())
        breathingSessions.append(session)
        do {
            try await SupabaseManager.shared.client.from("breathing_sessions").insert(session).execute()
        } catch { print("Insert error: \(error)") }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func logJpmrSession(userId: UUID, durationSeconds: Int) async {
        let points = 30
        let session = JpmrSession(userId: userId, durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date())
        jpmrSessions.append(session)
        do {
            try await SupabaseManager.shared.client.from("jpmr_sessions").insert(session).execute()
        } catch { print("Insert error: \(error)") }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func logGuidedMeditationSession(userId: UUID, meditationName: String, durationSeconds: Int) async {
        let points = 50
        let session = GuidedMeditationSession(userId: userId, meditationName: meditationName, durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date())
        guidedMeditationSessions.append(session)
        do {
            try await SupabaseManager.shared.client.from("guided_meditation_sessions").insert(session).execute()
        } catch { print("Insert error: \(error)") }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    // MARK: - ASMR
    func playAsmrSound(_ sound: AsmrSound) { activeAsmrSound = sound }
    func stopAsmrSound() { activeAsmrSound = nil }

    func toggleAsmrFavourite(soundId: UUID, userId: UUID) {
        if favouriteAsmrSoundIds.contains(soundId) {
            favouriteAsmrSoundIds.remove(soundId)
            Task {
                do {
                    try await SupabaseManager.shared.client.from("user_favourite_asmr_sounds")
                        .delete()
                        .eq("user_id", value: userId.uuidString)
                        .eq("sound_id", value: soundId.uuidString)
                        .execute()
                } catch { print("Delete error: \(error)") }
            }
        } else {
            favouriteAsmrSoundIds.insert(soundId)
            let fav = UserFavouriteAsmrSound(userId: userId, soundId: soundId, savedAt: Date())
            Task {
                do {
                    try await SupabaseManager.shared.client.from("user_favourite_asmr_sounds").insert(fav).execute()
                } catch { print("Insert error: \(error)") }
            }
        }
    }

    // MARK: - Brain Dump Folders
    func addBrainDumpFolder(name: String, userId: UUID) {
        let folder = BrainDumpFolder(userId: userId, name: name, entryCount: 0)
        brainDumpFolders.append(folder)
        Task {
            do {
                try await SupabaseManager.shared.client.from("brain_dump_folders").insert(folder).execute()
            } catch { print("Insert error: \(error)") }
        }
    }

    func updateBrainDumpFolder(_ folder: BrainDumpFolder) {
        if let index = brainDumpFolders.firstIndex(where: { $0.id == folder.id }) {
            brainDumpFolders[index] = folder
            Task {
                do {
                    try await SupabaseManager.shared.client.from("brain_dump_folders")
                        .update(folder)
                        .eq("id", value: folder.id.uuidString)
                        .execute()
                } catch { print("Update error: \(error)") }
            }
        }
    }

    func deleteBrainDumpFolder(_ folder: BrainDumpFolder) {
        brainDumpFolders.removeAll { $0.id == folder.id }
        for i in brainDumpEntries.indices where brainDumpEntries[i].folderId == folder.id {
            brainDumpEntries[i].folderId = nil
            let entry = brainDumpEntries[i]
            Task {
                do {
                    try await SupabaseManager.shared.client.from("brain_dump_entries")
                        .update(entry)
                        .eq("id", value: entry.id.uuidString)
                        .execute()
                } catch { print("Update error: \(error)") }
            }
        }
        Task {
            do {
                try await SupabaseManager.shared.client.from("brain_dump_folders")
                    .delete()
                    .eq("id", value: folder.id.uuidString)
                    .execute()
            } catch { print("Delete error: \(error)") }
        }
    }

    // MARK: - Brain Dump Entries
    func addBrainDumpEntry(content: String, drawingData: Data? = nil, title: String? = nil, userId: UUID, folderId: UUID? = nil) async {
        let points = 10
        let entry = BrainDumpEntry(userId: userId, folderId: folderId, title: title, content: content, drawingData: drawingData, pointsEarned: points, createdAt: Date())
        brainDumpEntries.append(entry)
        if let folderId, let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
            brainDumpFolders[index].entryCount += 1
            let folder = brainDumpFolders[index]
            do {
                try await SupabaseManager.shared.client.from("brain_dump_folders").update(folder).eq("id", value: folder.id.uuidString).execute()
            } catch { print("Update error: \(error)") }
        }
        do {
            try await SupabaseManager.shared.client.from("brain_dump_entries").insert(entry).execute()
        } catch { print("Insert error: \(error)") }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func updateBrainDumpEntry(_ entry: BrainDumpEntry) {
        if let index = brainDumpEntries.firstIndex(where: { $0.id == entry.id }) {
            brainDumpEntries[index] = entry
            Task {
                do {
                    try await SupabaseManager.shared.client.from("brain_dump_entries")
                        .update(entry)
                        .eq("id", value: entry.id.uuidString)
                        .execute()
                } catch { print("Update error: \(error)") }
            }
        }
    }

    func deleteBrainDumpEntry(_ entry: BrainDumpEntry) {
        brainDumpEntries.removeAll { $0.id == entry.id }
        if let folderId = entry.folderId, let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
            brainDumpFolders[index].entryCount = max(0, brainDumpFolders[index].entryCount - 1)
            let folder = brainDumpFolders[index]
            Task {
                do {
                    try await SupabaseManager.shared.client.from("brain_dump_folders").update(folder).eq("id", value: folder.id.uuidString).execute()
                } catch { print("Update error: \(error)") }
            }
        }
        Task {
            do {
                try await SupabaseManager.shared.client.from("brain_dump_entries")
                    .delete()
                    .eq("id", value: entry.id.uuidString)
                    .execute()
            } catch { print("Delete error: \(error)") }
        }
    }

    func clearData() {
        breathingSessions.removeAll()
        jpmrSessions.removeAll()
        guidedMeditationSessions.removeAll()
        asmrSounds.removeAll()
        favouriteAsmrSoundIds.removeAll()
        brainDumpFolders.removeAll()
        brainDumpEntries.removeAll()
        activeAsmrSound = nil
        errorMessage = nil
    }
}
