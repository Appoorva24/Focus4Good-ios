import Foundation

//BreathingSession
struct BreathingSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var cyclesCompleted: Int
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

//JpmrSession
struct JpmrSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date
}

//JpmrVideo
struct JpmrVideo: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var videoUrl: String

    enum CodingKeys: String, CodingKey {
        case id, title
        case videoUrl = "video_url"
    }
}

//GuidedMeditationSession
struct GuidedMeditationSession: Codable {
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
    var title: String?
    var content: String
    var drawingData: Data?
    var pointsEarned: Int
    var createdAt: Date
}

//ASMRPlaylist
struct ASMRPlaylist: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var purpose: String
    var coverImageName: String
    var placeholderColorHex: String
    var sounds: [AsmrSound]
}
