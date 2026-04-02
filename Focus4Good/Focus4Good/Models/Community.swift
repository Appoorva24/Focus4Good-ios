


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
