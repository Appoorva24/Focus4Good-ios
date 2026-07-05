import Foundation

//BreathingSession
struct BreathingSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var cyclesCompleted: Int
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cyclesCompleted = "cycles_completed"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
}

//JpmrSession
struct JpmrSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
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

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case meditationName = "meditation_name"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
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

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case soundId = "sound_id"
        case savedAt = "saved_at"
    }
}

//BrainDumpFolder
struct BrainDumpFolder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var name: String
    var entryCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case entryCount = "entry_count"
    }
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

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case folderId = "folder_id"
        case title, content
        case drawingData = "drawing_data"
        case pointsEarned = "points_earned"
        case createdAt = "created_at"
    }
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
