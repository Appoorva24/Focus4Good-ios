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

    func fetchBreathingSessions(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchJpmrSessions(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchGuidedMeditationSessions(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchAsmrSounds() async { isLoading = true; isLoading = false }
    func fetchFavouriteAsmrSounds(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchBrainDumpFolders(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchBrainDumpEntries(userId: UUID) async { isLoading = true; isLoading = false }

    // MARK: - Log Sessions
    func logBreathingSession(userId: UUID, cyclesCompleted: Int, durationSeconds: Int) async {
        let points = cyclesCompleted * 10
        breathingSessions.append(BreathingSession(userId: userId, cyclesCompleted: cyclesCompleted, durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date()))
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func logJpmrSession(userId: UUID, durationSeconds: Int) async {
        let points = 30
        jpmrSessions.append(JpmrSession(userId: userId, durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date()))
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func logGuidedMeditationSession(userId: UUID, meditationName: String, durationSeconds: Int) async {
        let points = 50
        guidedMeditationSessions.append(GuidedMeditationSession(userId: userId, meditationName: meditationName, durationSeconds: durationSeconds, pointsEarned: points, completedAt: Date()))
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    // MARK: - ASMR
    func playAsmrSound(_ sound: AsmrSound) { activeAsmrSound = sound }
    func stopAsmrSound() { activeAsmrSound = nil }

    func toggleAsmrFavourite(soundId: UUID, userId: UUID) {
        if favouriteAsmrSoundIds.contains(soundId) { favouriteAsmrSoundIds.remove(soundId) }
        else { favouriteAsmrSoundIds.insert(soundId) }
    }

    // MARK: - Brain Dump Folders
    func addBrainDumpFolder(name: String, userId: UUID) {
        brainDumpFolders.append(BrainDumpFolder(userId: userId, name: name, entryCount: 0))
    }

    func updateBrainDumpFolder(_ folder: BrainDumpFolder) {
        if let index = brainDumpFolders.firstIndex(where: { $0.id == folder.id }) { brainDumpFolders[index] = folder }
    }

    func deleteBrainDumpFolder(_ folder: BrainDumpFolder) {
        brainDumpFolders.removeAll { $0.id == folder.id }
        for i in brainDumpEntries.indices where brainDumpEntries[i].folderId == folder.id { brainDumpEntries[i].folderId = nil }
    }

    // MARK: - Brain Dump Entries
    func addBrainDumpEntry(content: String, drawingData: Data? = nil, title: String? = nil, userId: UUID, folderId: UUID? = nil) async {
        let points = 10
        brainDumpEntries.append(BrainDumpEntry(userId: userId, folderId: folderId, title: title, content: content, drawingData: drawingData, pointsEarned: points, createdAt: Date()))
        if let folderId, let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) { brainDumpFolders[index].entryCount += 1 }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func updateBrainDumpEntry(_ entry: BrainDumpEntry) {
        if let index = brainDumpEntries.firstIndex(where: { $0.id == entry.id }) { brainDumpEntries[index] = entry }
    }

    func deleteBrainDumpEntry(_ entry: BrainDumpEntry) {
        brainDumpEntries.removeAll { $0.id == entry.id }
        if let folderId = entry.folderId, let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
            brainDumpFolders[index].entryCount = max(0, brainDumpFolders[index].entryCount - 1)
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
