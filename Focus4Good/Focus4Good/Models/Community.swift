import Foundation

// MARK: - CommunityCategory
struct CommunityCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
}

// MARK: - Community
struct Community: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var categoryId: UUID?
    var creatorId: UUID
    var name: String
    var description: String
    var coverImageUrl: String?
    var isPrivate: Bool
    var memberCount: Int
    var createdAt: Date
}

// MARK: - CommunityMember
struct CommunityMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var communityId: UUID
    var role: String
    var joinedAt: Date
}

// MARK: - Post
struct Post: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var authorId: UUID
    var communityId: UUID
    var content: String
    var imageUrl: String?
    var hashtag: String?
    var likeCount: Int
    var createdAt: Date
}

// MARK: - PostLike
struct PostLike: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID
    var createdAt: Date
}

// MARK: - PostComment
struct PostComment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID
    var content: String
    var createdAt: Date
}
