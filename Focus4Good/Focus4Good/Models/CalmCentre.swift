import Foundation

// MARK: - BreathingSession
struct BreathingSession: Identifiable, Hashable {
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

extension BreathingSession: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        userId          = try c.decode(UUID.self, forKey: .userId)
        cyclesCompleted = try c.decode(Int.self, forKey: .cyclesCompleted)
        durationSeconds = try c.decode(Int.self, forKey: .durationSeconds)
        pointsEarned    = try c.decode(Int.self, forKey: .pointsEarned)
        completedAt     = SupabaseDateCoding.flexDecode(from: c, key: .completedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(cyclesCompleted, forKey: .cyclesCompleted)
        try c.encode(durationSeconds, forKey: .durationSeconds)
        try c.encode(pointsEarned, forKey: .pointsEarned)
        try c.encode(SupabaseDateCoding.encodeTimestamp(completedAt), forKey: .completedAt)
    }
}

// MARK: - JpmrSession
struct JpmrSession: Identifiable, Hashable {
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

extension JpmrSession: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        userId          = try c.decode(UUID.self, forKey: .userId)
        durationSeconds = try c.decode(Int.self, forKey: .durationSeconds)
        pointsEarned    = try c.decode(Int.self, forKey: .pointsEarned)
        completedAt     = SupabaseDateCoding.flexDecode(from: c, key: .completedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(durationSeconds, forKey: .durationSeconds)
        try c.encode(pointsEarned, forKey: .pointsEarned)
        try c.encode(SupabaseDateCoding.encodeTimestamp(completedAt), forKey: .completedAt)
    }
}

// MARK: - GuidedMeditationSession
struct GuidedMeditationSession: Identifiable, Hashable {
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

extension GuidedMeditationSession: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        userId          = try c.decode(UUID.self, forKey: .userId)
        meditationName  = try c.decode(String.self, forKey: .meditationName)
        durationSeconds = try c.decode(Int.self, forKey: .durationSeconds)
        pointsEarned    = try c.decode(Int.self, forKey: .pointsEarned)
        completedAt     = SupabaseDateCoding.flexDecode(from: c, key: .completedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(meditationName, forKey: .meditationName)
        try c.encode(durationSeconds, forKey: .durationSeconds)
        try c.encode(pointsEarned, forKey: .pointsEarned)
        try c.encode(SupabaseDateCoding.encodeTimestamp(completedAt), forKey: .completedAt)
    }
}

// MARK: - AsmrSound (no Date fields — auto-Codable is fine)
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

// MARK: - AsmrFavourite (no Date fields — auto-Codable is fine)
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

// MARK: - BrainDumpFolder (no Date fields — auto-Codable is fine)
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

// MARK: - BrainDumpEntry
struct BrainDumpEntry: Identifiable, Hashable {
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

extension BrainDumpEntry: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self, forKey: .id)
        userId       = try c.decode(UUID.self, forKey: .userId)
        folderId     = try c.decodeIfPresent(UUID.self, forKey: .folderId)
        content      = try c.decode(String.self, forKey: .content)
        pointsEarned = try c.decode(Int.self, forKey: .pointsEarned)
        createdAt    = SupabaseDateCoding.flexDecode(from: c, key: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encodeIfPresent(folderId, forKey: .folderId)
        try c.encode(content, forKey: .content)
        try c.encode(pointsEarned, forKey: .pointsEarned)
        try c.encode(SupabaseDateCoding.encodeTimestamp(createdAt), forKey: .createdAt)
    }
}
