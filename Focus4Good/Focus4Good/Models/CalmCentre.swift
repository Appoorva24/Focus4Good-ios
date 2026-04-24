import Foundation

//BreathingSession
struct BreathingSession: Identifiable, Codable, Hashable {
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
struct JpmrSession: Identifiable, Codable, Hashable {
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

//GuidedMeditationSession
struct GuidedMeditationSession: Identifiable, Codable, Hashable {
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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case audioUrl = "audio_url"
        case imageUrl = "image_url"
        case durationSeconds = "duration_seconds"
    }
}

// AsmrFavourite (join table)
struct AsmrFavourite: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var soundId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case soundId = "sound_id"
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
    var content: String
    var pointsEarned: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case folderId = "folder_id"
        case content
        case pointsEarned = "points_earned"
        case createdAt = "created_at"
    }
}
