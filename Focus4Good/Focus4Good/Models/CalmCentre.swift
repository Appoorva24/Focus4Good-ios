import Foundation

// MARK: - BreathingSession
struct BreathingSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var techniqueName: String
    var cyclesCompleted: Int
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

// MARK: - JpmrSession
struct JpmrSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

// MARK: - GuidedMeditationSession
struct GuidedMeditationSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var meditationName: String
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

// MARK: - AsmrSound
struct AsmrSound: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var category: String
    var audioUrl: String
    var imageUrl: String
    var durationSeconds: Int
}

// MARK: - UserFavouriteAsmrSound
struct UserFavouriteAsmrSound: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var soundId: UUID
    var savedAt: Date
}

// MARK: - BrainDumpFolder
struct BrainDumpFolder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var name: String
    var entryCount: Int
}

// MARK: - BrainDumpEntry
struct BrainDumpEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var folderId: UUID?
    var content: String
    var pointsEarned: Int
    var createdAt: Date
}
