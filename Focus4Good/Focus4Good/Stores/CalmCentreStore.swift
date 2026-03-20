import Foundation
import Combine

@MainActor
final class CalmCentreStore: ObservableObject {

    // MARK: - State
    @Published var breathingSessions: [BreathingSession] = []
    @Published var jpmrSessions: [JpmrSession] = []
    @Published var guidedMeditationSessions: [GuidedMeditationSession] = []
    @Published var asmrSounds: [AsmrSound] = []
    @Published var favouriteAsmrSoundIds: Set<UUID> = []
    @Published var brainDumpFolders: [BrainDumpFolder] = []
    @Published var brainDumpEntries: [BrainDumpEntry] = []
    @Published var activeAsmrSound: AsmrSound?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed
    var favouriteAsmrSounds: [AsmrSound] { asmrSounds.filter { favouriteAsmrSoundIds.contains($0.id) } }
    var asmrSoundsByCategory: [String: [AsmrSound]] { Dictionary(grouping: asmrSounds, by: { $0.category }) }

    var totalCalmMinutesToday: Int {
        let calendar = Calendar.current
        let breathingMinutes = breathingSessions
            .filter { calendar.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + ($1.durationSeconds / 60) }
        let jpmrMinutes = jpmrSessions
            .filter { calendar.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + ($1.durationSeconds / 60) }
        let meditationMinutes = guidedMeditationSessions
            .filter { calendar.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + ($1.durationSeconds / 60) }
        return breathingMinutes + jpmrMinutes + meditationMinutes
    }

    func brainDumpEntries(in folder: BrainDumpFolder) -> [BrainDumpEntry] {
        brainDumpEntries.filter { $0.folderId == folder.id }
    }

    var recentBrainDumpEntries: [BrainDumpEntry] {
        brainDumpEntries.sorted { $0.createdAt > $1.createdAt }
    }

    static let shared = CalmCentreStore()
    private init() {}

    // MARK: - Breathing
    func fetchBreathingSessions(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func logBreathingSession(userId: UUID, techniqueName: String, cyclesCompleted: Int, durationSeconds: Int) async {
        let points = cyclesCompleted * 10
        let session = BreathingSession(
            userId: userId,
            techniqueName: techniqueName,
            cyclesCompleted: cyclesCompleted,
            durationSeconds: durationSeconds,
            pointsEarned: points,
            completedAt: Date()
        )
        breathingSessions.append(session)
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    // MARK: - JPMR
    func fetchJpmrSessions(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func logJpmrSession(userId: UUID, durationSeconds: Int) async {
        let points = 30
        let session = JpmrSession(
            userId: userId,
            durationSeconds: durationSeconds,
            pointsEarned: points,
            completedAt: Date()
        )
        jpmrSessions.append(session)
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    // MARK: - Guided Meditation
    func fetchGuidedMeditationSessions(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func logGuidedMeditationSession(userId: UUID, meditationName: String, durationSeconds: Int) async {
        let points = 50
        let session = GuidedMeditationSession(
            userId: userId,
            meditationName: meditationName,
            durationSeconds: durationSeconds,
            pointsEarned: points,
            completedAt: Date()
        )
        guidedMeditationSessions.append(session)
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addCalmCentreTime(minutes: durationSeconds / 60, userId: userId)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    // MARK: - ASMR
    func fetchAsmrSounds() async {
        isLoading = true
        do { isLoading = false }
    }

    func fetchFavouriteAsmrSounds(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func playAsmrSound(_ sound: AsmrSound) { activeAsmrSound = sound }
    func stopAsmrSound() { activeAsmrSound = nil }

    func toggleAsmrFavourite(soundId: UUID, userId: UUID) async {
        if favouriteAsmrSoundIds.contains(soundId) {
            favouriteAsmrSoundIds.remove(soundId)
        } else {
            favouriteAsmrSoundIds.insert(soundId)
        }
    }

    // MARK: - Brain Dump Folders
    func fetchBrainDumpFolders(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func addBrainDumpFolder(name: String, userId: UUID) async {
        let folder = BrainDumpFolder(userId: userId, name: name, entryCount: 0)
        brainDumpFolders.append(folder)
    }

    func updateBrainDumpFolder(_ folder: BrainDumpFolder) async {
        if let index = brainDumpFolders.firstIndex(where: { $0.id == folder.id }) {
            brainDumpFolders[index] = folder
        }
    }

    func deleteBrainDumpFolder(_ folder: BrainDumpFolder) async {
        brainDumpFolders.removeAll { $0.id == folder.id }
        for i in brainDumpEntries.indices where brainDumpEntries[i].folderId == folder.id {
            brainDumpEntries[i].folderId = nil
        }
    }

    // MARK: - Brain Dump Entries
    func fetchBrainDumpEntries(userId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func addBrainDumpEntry(content: String, userId: UUID, folderId: UUID? = nil) async {
        let points = 10
        let entry = BrainDumpEntry(
            userId: userId,
            folderId: folderId,
            content: content,
            pointsEarned: points,
            createdAt: Date()
        )
        brainDumpEntries.append(entry)
        if let folderId, let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
            brainDumpFolders[index].entryCount += 1
        }
        await UserStore.shared.updateFocusPoints(by: points)
        await ProgressStore.shared.addPointsEarned(points: points, userId: userId)
    }

    func updateBrainDumpEntry(_ entry: BrainDumpEntry) async {
        if let index = brainDumpEntries.firstIndex(where: { $0.id == entry.id }) {
            brainDumpEntries[index] = entry
        }
    }

    func deleteBrainDumpEntry(_ entry: BrainDumpEntry) async {
        brainDumpEntries.removeAll { $0.id == entry.id }
        if let folderId = entry.folderId,
           let index = brainDumpFolders.firstIndex(where: { $0.id == folderId }) {
            brainDumpFolders[index].entryCount = max(0, brainDumpFolders[index].entryCount - 1)
        }
    }
}
