import Foundation


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
    var coverImageData: Data?
    var isPrivate: Bool
    var memberCount: Int
    var createdAt: Date
}

// MARK: - CommunityMember
//many to many relateionship
// one user-> multiple community && one commmunity -> multiple user

struct CommunityMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var communityId: UUID
    var role: String // also i use enum instead of string (for backend later)
    var joinedAt: Date
}

// MARK: - Post
struct Post: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var authorId: UUID
    var authorName: String = "Anonymous"
    var authorImageUrl: String?
    var communityId: UUID
    var content: String
    var imageUrl: String?
    var postImageName: String?
    var postImageData: Data?
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
    var authorName: String = "Anonymous"
    var authorImageUrl: String?
    var createdAt: Date
}
