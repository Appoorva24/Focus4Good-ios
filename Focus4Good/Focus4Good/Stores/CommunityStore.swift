import Foundation
import Combine

@MainActor
final class CommunityStore: ObservableObject {

    // MARK: - State
    @Published var communities: [Community] = []
    @Published var communityCategories: [CommunityCategory] = []
    @Published var communityMembers: [CommunityMember] = []
    @Published var posts: [Post] = []
    @Published var postLikes: [PostLike] = []
    @Published var postComments: [PostComment] = []
    @Published var selectedCommunity: Community?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed
    func posts(in community: Community) -> [Post] {
        posts.filter { $0.communityId == community.id }.sorted { $0.createdAt > $1.createdAt }
    }

    func comments(for post: Post) -> [PostComment] {
        postComments.filter { $0.postId == post.id }.sorted { $0.createdAt < $1.createdAt }
    }

    func isLiked(postId: UUID, userId: UUID) -> Bool {
        postLikes.contains { $0.postId == postId && $0.userId == userId }
    }

    func isMember(communityId: UUID, userId: UUID) -> Bool {
        communityMembers.contains { $0.communityId == communityId && $0.userId == userId }
    }

    func communities(in category: CommunityCategory) -> [Community] {
        communities.filter { $0.categoryId == category.id }
    }

    func memberRole(communityId: UUID, userId: UUID) -> String? {
        communityMembers.first { $0.communityId == communityId && $0.userId == userId }?.role
    }

    static let shared = CommunityStore()
    private init() {}

    // MARK: - Communities
    func fetchCommunities() async {
        isLoading = true
        do { isLoading = false }
    }

    func fetchCommunityCategories() async {
        isLoading = true
        do { isLoading = false }
    }

    func createCommunity(name: String, description: String, categoryId: UUID?, isPrivate: Bool, userId: UUID) async {
        let community = Community(
            categoryId: categoryId,
            creatorId: userId,
            name: name,
            description: description,
            coverImageUrl: nil,
            isPrivate: isPrivate,
            memberCount: 1,
            createdAt: Date()
        )
        communities.append(community)
        let member = CommunityMember(userId: userId, communityId: community.id, role: "admin", joinedAt: Date())
        communityMembers.append(member)
    }

    func joinCommunity(_ community: Community, userId: UUID) async {
        guard !isMember(communityId: community.id, userId: userId) else { return }
        let member = CommunityMember(userId: userId, communityId: community.id, role: "member", joinedAt: Date())
        communityMembers.append(member)
        if let index = communities.firstIndex(where: { $0.id == community.id }) {
            communities[index].memberCount += 1
        }
    }

    func leaveCommunity(_ community: Community, userId: UUID) async {
        communityMembers.removeAll { $0.communityId == community.id && $0.userId == userId }
        if let index = communities.firstIndex(where: { $0.id == community.id }) {
            communities[index].memberCount = max(0, communities[index].memberCount - 1)
        }
    }

    // MARK: - Posts
    func fetchPosts(communityId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func createPost(content: String, communityId: UUID, authorId: UUID, imageUrl: String? = nil, hashtag: String? = nil) async {
        let post = Post(
            authorId: authorId,
            communityId: communityId,
            content: content,
            imageUrl: imageUrl,
            hashtag: hashtag,
            likeCount: 0,
            createdAt: Date()
        )
        posts.append(post)
    }

    func deletePost(_ post: Post) async {
        posts.removeAll { $0.id == post.id }
        postComments.removeAll { $0.postId == post.id }
        postLikes.removeAll { $0.postId == post.id }
    }

    // MARK: - Likes
    func toggleLike(postId: UUID, userId: UUID) async {
        if let likeIndex = postLikes.firstIndex(where: { $0.postId == postId && $0.userId == userId }) {
            postLikes.remove(at: likeIndex)
            if let postIndex = posts.firstIndex(where: { $0.id == postId }) {
                posts[postIndex].likeCount = max(0, posts[postIndex].likeCount - 1)
            }
        } else {
            postLikes.append(PostLike(userId: userId, postId: postId, createdAt: Date()))
            if let postIndex = posts.firstIndex(where: { $0.id == postId }) {
                posts[postIndex].likeCount += 1
            }
        }
    }

    // MARK: - Comments
    func fetchComments(postId: UUID) async {
        isLoading = true
        do { isLoading = false }
    }

    func addComment(content: String, postId: UUID, userId: UUID) async {
        let comment = PostComment(userId: userId, postId: postId, content: content, createdAt: Date())
        postComments.append(comment)
    }

    func deleteComment(_ comment: PostComment) async {
        postComments.removeAll { $0.id == comment.id }
    }
}
