import Foundation

@Observable
class CalmCentreStore {

    // MARK: - State
    var breathingSessions: [BreathingSession] = []
    var jpmrSessions: [JpmrSession] = []
    var meditationSessions: [GuidedMeditationSession] = []
    var asmrSounds: [AsmrSound] = []
    var favouriteAsmrSounds: [UserFavouriteAsmrSound] = []
    var brainDumpFolders: [BrainDumpFolder] = []
    var dumpEntries: [BrainDumpEntry] = []
    var activeAsmrSound: AsmrSound?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
    var totalCalmMinutes: Int {
        let breathe = breathingSessions.reduce(0) { $0 + $1.durationSeconds }
        let jpmr = jpmrSessions.reduce(0) { $0 + $1.durationSeconds }
        let meditation = meditationSessions.reduce(0) { $0 + $1.durationSeconds }
        return (breathe + jpmr + meditation) / 60
    }

    func entries(in folder: BrainDumpFolder) -> [BrainDumpEntry] {
        dumpEntries.filter { $0.folderId == folder.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func isFavourite(soundId: UUID, userId: UUID) -> Bool {
        favouriteAsmrSounds.contains { $0.soundId == soundId && $0.userId == userId }
    }

    static let shared = CalmCentreStore()
    private init() {}

    // MARK: - Fetch
    func fetchBreathingSessions(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchJpmrSessions(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchMeditationSessions(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchAsmrSounds() async { isLoading = true; isLoading = false }
    func fetchBrainDumpFolders(userId: UUID) async { isLoading = true; isLoading = false }
    func fetchBrainDumpEntries(userId: UUID) async { isLoading = true; isLoading = false }

    // MARK: - Breathing
    func recordBreathingSession(userId: UUID, technique: String, cycles: Int, duration: Int, points: Int) async {
        breathingSessions.append(BreathingSession(
            userId: userId, techniqueName: technique,
            cyclesCompleted: cycles, durationSeconds: duration,
            pointsEarned: points, completedAt: Date()
        ))
    }

    /// Convenience used by BreatheSessionView at session completion.
    func logBreathingSession(userId: UUID, techniqueName: String, cyclesCompleted: Int, durationSeconds: Int) async {
        let points = cyclesCompleted * 10
        await recordBreathingSession(userId: userId, technique: techniqueName, cycles: cyclesCompleted, duration: durationSeconds, points: points)
    }

    // MARK: - JPMR
    func recordJpmrSession(userId: UUID, duration: Int, points: Int) async {
        jpmrSessions.append(JpmrSession(
            userId: userId, durationSeconds: duration,
            pointsEarned: points, completedAt: Date()
        ))
    }

    /// Convenience used by JPMRSessionView at session completion.
    func logJpmrSession(userId: UUID, durationSeconds: Int) async {
        let points = max(1, durationSeconds / 60) * 10
        await recordJpmrSession(userId: userId, duration: durationSeconds, points: points)
    }

    // MARK: - Meditation
    func recordMeditationSession(userId: UUID, name: String, duration: Int, points: Int) async {
        meditationSessions.append(GuidedMeditationSession(
            userId: userId, meditationName: name,
            durationSeconds: duration, pointsEarned: points,
            completedAt: Date()
        ))
    }

    /// Convenience used by DeepFocusBrowseView at session completion.
    func logGuidedMeditationSession(userId: UUID, meditationName: String, durationSeconds: Int) async {
        let points = max(1, durationSeconds / 60) * 10
        await recordMeditationSession(userId: userId, name: meditationName, duration: durationSeconds, points: points)
    }

    // MARK: - Brain Dump

    /// Returns entries in a specific folder (called by BraindumpEntriesView + BraindumpFoldersView).
    func brainDumpEntries(in folder: BrainDumpFolder) -> [BrainDumpEntry] {
        dumpEntries.filter { $0.folderId == folder.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Called by BraindumpFoldersView (synchronous).
    func addBrainDumpFolder(name: String, userId: UUID) {
        brainDumpFolders.append(BrainDumpFolder(
            userId: userId, name: name, entryCount: 0
        ))
    }

    /// Called by BraindumpFoldersView (synchronous).
    func deleteBrainDumpFolder(_ folder: BrainDumpFolder) {
        // Also delete all entries in this folder
        dumpEntries.removeAll { $0.folderId == folder.id }
        brainDumpFolders.removeAll { $0.id == folder.id }
    }

    /// Called by BraindumpEditorView (async, different param order).
    func addBrainDumpEntry(content: String, userId: UUID, folderId: UUID?) async {
        dumpEntries.append(BrainDumpEntry(
            userId: userId, folderId: folderId,
            content: content, pointsEarned: 10, createdAt: Date()
        ))
        if let folderId,
           let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
            brainDumpFolders[index].entryCount += 1
        }
    }

    /// Called by BraindumpEntriesView (synchronous).
    func deleteBrainDumpEntry(_ entry: BrainDumpEntry) {
        if let folderId = entry.folderId,
           let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
            brainDumpFolders[index].entryCount = max(0, brainDumpFolders[index].entryCount - 1)
        }
        dumpEntries.removeAll { $0.id == entry.id }
    }

    // MARK: - ASMR Playback
    func playAsmrSound(_ sound: AsmrSound) {
        activeAsmrSound = sound
    }

    // MARK: - ASMR Favourites
    func toggleFavourite(soundId: UUID, userId: UUID) async {
        if let index = favouriteAsmrSounds.firstIndex(where: { $0.soundId == soundId && $0.userId == userId }) {
            favouriteAsmrSounds.remove(at: index)
        } else {
            favouriteAsmrSounds.append(UserFavouriteAsmrSound(
                userId: userId, soundId: soundId, savedAt: Date()
            ))
        }
    }
}
