import Foundation


//why take this : because their is multiple type of community like tech etc so it repeated 1000 times that why i take community category. 

struct CommunityCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
}

// MARK: - Community
struct Community: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var categoryId: UUID?  //reference of community category // why use id : api friendly avoid duplication and lightweight \\ also we create like category : communitycategory
//but what if 1000 thoudand community having multiple repated community so this things happen that why use uuid 
    //it just a copy of data not refrence that why changing category does not effect other category even having same uuid 
    
    var creatorId: UUID
    var name: String
    var description: String
    var coverImageUrl: String?
    var isPrivate: Bool
    var memberCount: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case creatorId = "creator_id"
        case name
        case description
        case coverImageUrl = "cover_image_url"
        case isPrivate = "is_private"
        case memberCount = "member_count"
        case createdAt = "created_at"
    }
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

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case communityId = "community_id"
        case role
        case joinedAt = "joined_at"
    }
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

    // Joined fields — populated client-side from profiles, not stored in DB
    var authorName: String?
    var authorImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case communityId = "community_id"
        case content
        case imageUrl = "image_url"
        case hashtag
        case likeCount = "like_count"
        case createdAt = "created_at"
        // authorName and authorImageUrl are NOT in the DB — excluded from CodingKeys
    }
}

// MARK: - PostLike
struct PostLike: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case createdAt = "created_at"
    }
}

// MARK: - PostComment
struct PostComment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID
    var content: String
    var createdAt: Date

    // Joined fields — populated client-side from profiles
    var authorName: String?
    var authorImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case content
        case createdAt = "created_at"
        // authorName and authorImageUrl are NOT in the DB
    }
}

// MARK: - SavedPost
struct SavedPost: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
    }
}
