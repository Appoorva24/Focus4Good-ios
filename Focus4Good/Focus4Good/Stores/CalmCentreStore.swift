import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class CommunityStore {

    // MARK: - State
    var communities: [Community] = []
    var communityCategories: [CommunityCategory] = []
    var communityMembers: [CommunityMember] = []
    var posts: [Post] = []
    var postLikes: [PostLike] = []
    var postComments: [PostComment] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
    func posts(in community: Community) -> [Post] {
        posts.filter { $0.communityId == community.id }.sorted { $0.createdAt > $1.createdAt }
    }
    func comments(for post: Post) -> [PostComment] {
        postComments.filter { $0.postId == post.id }.sorted { $0.createdAt < $1.createdAt }
    }
    func isLiked(postId: UUID, userId: UUID) -> Bool { postLikes.contains { $0.postId == postId && $0.userId == userId } }
    func isMember(communityId: UUID, userId: UUID) -> Bool { communityMembers.contains { $0.communityId == communityId && $0.userId == userId } }
    func communities(in category: CommunityCategory) -> [Community] { communities.filter { $0.categoryId == category.id } }
    func memberRole(communityId: UUID, userId: UUID) -> String? { communityMembers.first { $0.communityId == communityId && $0.userId == userId }?.role }

    static let shared = CommunityStore()
    private init() {}

    // MARK: - Fetch
    func fetchCommunities() async { isLoading = true; isLoading = false }
    func fetchCommunityCategories() async { isLoading = true; isLoading = false }
    func fetchPosts(communityId: UUID) async { isLoading = true; isLoading = false }
    func fetchComments(postId: UUID) async { isLoading = true; isLoading = false }

    // MARK: - Communities
    func createCommunity(name: String, description: String, categoryId: UUID?, isPrivate: Bool, userId: UUID) async {
        let community = Community(categoryId: categoryId, creatorId: userId, name: name, description: description, coverImageUrl: nil, isPrivate: isPrivate, memberCount: 1, createdAt: Date())
        communities.append(community)
        communityMembers.append(CommunityMember(userId: userId, communityId: community.id, role: "admin", joinedAt: Date()))
    }

    func joinCommunity(_ community: Community, userId: UUID) async {
        guard !isMember(communityId: community.id, userId: userId) else { return }
        communityMembers.append(CommunityMember(userId: userId, communityId: community.id, role: "member", joinedAt: Date()))
        if let index = communities.firstIndex(where: { $0.id == community.id }) { communities[index].memberCount += 1 }
    }

    func leaveCommunity(_ community: Community, userId: UUID) async {
        communityMembers.removeAll { $0.communityId == community.id && $0.userId == userId }
        if let index = communities.firstIndex(where: { $0.id == community.id }) { communities[index].memberCount = max(0, communities[index].memberCount - 1) }
    }

    // MARK: - Posts
    func createPost(content: String, communityId: UUID, authorId: UUID, imageUrl: String? = nil, hashtag: String? = nil) async {
        posts.append(Post(authorId: authorId, communityId: communityId, content: content, imageUrl: imageUrl, hashtag: hashtag, likeCount: 0, createdAt: Date()))
    }

    func deletePost(_ post: Post) async {
        posts.removeAll { $0.id == post.id }
        postComments.removeAll { $0.postId == post.id }
        postLikes.removeAll { $0.postId == post.id }
    }

    func toggleLike(postId: UUID, userId: UUID) async {
        if let i = postLikes.firstIndex(where: { $0.postId == postId && $0.userId == userId }) {
            postLikes.remove(at: i)
            if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount = max(0, posts[j].likeCount - 1) }
        } else {
            postLikes.append(PostLike(userId: userId, postId: postId, createdAt: Date()))
            if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount += 1 }
        }
    }

    func addComment(content: String, postId: UUID, userId: UUID) async {
        postComments.append(PostComment(userId: userId, postId: postId, content: content, createdAt: Date()))
    }

    func deleteComment(_ comment: PostComment) async {
        postComments.removeAll { $0.id == comment.id }
    }
}
