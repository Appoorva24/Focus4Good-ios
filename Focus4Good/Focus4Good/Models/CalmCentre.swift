import Foundation

//BreathingSession
struct BreathingSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var techniqueName: String
    var cyclesCompleted: Int
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

//JpmrSession
struct JpmrSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

//GuidedMeditationSession
struct GuidedMeditationSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var meditationName: String
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

//AsmrSound
struct AsmrSound: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var category: String
    var audioUrl: String
    var imageUrl: String
    var durationSeconds: Int
}

//UserFavouriteAsmrSound
struct UserFavouriteAsmrSound: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var soundId: UUID
    var savedAt: Date
}

//BrainDumpFolder
struct BrainDumpFolder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var name: String
    var entryCount: Int
}

//BrainDumpEntry
struct BrainDumpEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var folderId: UUID?
    var content: String
    var pointsEarned: Int
    var createdAt: Date
}
