import Foundation
import Supabase
import UIKit

@MainActor
@Observable
class CommunityStore {

    // MARK: - State
    var communities: [Community] = []
    var communityCategories: [CommunityCategory] = []
    var communityMembers: [CommunityMember] = []
    var posts: [Post] = []
    var postLikes: [PostLike] = []
    var postComments: [PostComment] = []
    var savedPostIds: Set<UUID> = []
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
    func isSaved(postId: UUID, userId: UUID) -> Bool { savedPostIds.contains(postId) }

    static let shared = CommunityStore()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    init() {}

    // MARK: - Clear (called on sign-out)
    func clearData() {
        communities = []
        communityCategories = []
        communityMembers = []
        posts = []
        postLikes = []
        postComments = []
        savedPostIds = []
    }

    // MARK: - Fetch
    func fetchCommunities() async {
        isLoading = true
        do {
            let fetched: [Community] = try await client
                .from("communities")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            communities = fetched
        } catch {
            errorMessage = "Failed to load communities: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchCommunityCategories() async {
        isLoading = true
        do {
            let fetched: [CommunityCategory] = try await client
                .from("community_categories")
                .select()
                .execute()
                .value
            communityCategories = fetched
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchMembers(communityId: UUID) async {
        do {
            let fetched: [CommunityMember] = try await client
                .from("community_members")
                .select()
                .eq("community_id", value: communityId.uuidString)
                .execute()
                .value
            // Merge — don't overwrite existing members from other communities
            let existingOther = communityMembers.filter { $0.communityId != communityId }
            communityMembers = existingOther + fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchPosts(communityId: UUID) async {
        isLoading = true
        do {
            let fetched: [Post] = try await client
                .from("posts")
                .select()
                .eq("community_id", value: communityId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            let populated = await populatePostAuthors(fetched)
            // Merge — don't overwrite posts from other communities
            let existingOther = posts.filter { $0.communityId != communityId }
            posts = existingOther + populated
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// Fetch posts from all communities the current user has joined or created
    func fetchPostsForJoinedCommunities(userId: UUID) async {
        let joinedIds = communityMembers
            .filter { $0.userId == userId }
            .map { $0.communityId }
        let createdIds = communities
            .filter { $0.creatorId == userId }
            .map { $0.id }
        let allIds = Set(joinedIds + createdIds)
        for communityId in allIds {
            await fetchPosts(communityId: communityId)
        }
    }

    /// Fetch all members across all communities
    func fetchAllMembers() async {
        do {
            let fetched: [CommunityMember] = try await client
                .from("community_members")
                .select()
                .execute()
                .value
            communityMembers = fetched
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
        }
    }

    func fetchLikes(postId: UUID) async {
        do {
            let fetched: [PostLike] = try await client
                .from("post_likes")
                .select()
                .eq("post_id", value: postId.uuidString)
                .execute()
                .value
            let existingOther = postLikes.filter { $0.postId != postId }
            postLikes = existingOther + fetched
            
            // Sync local likeCount with fetched database count
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].likeCount = fetched.count
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchComments(postId: UUID) async {
        do {
            let fetched: [PostComment] = try await client
                .from("post_comments")
                .select()
                .eq("post_id", value: postId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            let populated = await populateCommentAuthors(fetched)
            let existingOther = postComments.filter { $0.postId != postId }
            postComments = existingOther + populated
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
        }
    }

    func fetchSavedPosts(userId: UUID) async {
        do {
            let fetched: [SavedPost] = try await client
                .from("saved_posts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            savedPostIds = Set(fetched.map { $0.postId })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Communities
    func createCommunity(name: String, description: String, categoryId: UUID?, isPrivate: Bool, userId: UUID, coverImageUrl: String? = nil) async {
        let community = Community(
            categoryId: categoryId, creatorId: userId, name: name,
            description: description, coverImageUrl: coverImageUrl,
            isPrivate: isPrivate, memberCount: 1, createdAt: Date()
        )
        do {
            let inserted: Community = try await client
                .from("communities")
                .insert(community)
                .select().single().execute().value
            communities.insert(inserted, at: 0)

            // Auto-join as admin
            let member = CommunityMember(userId: userId, communityId: inserted.id, role: "admin", joinedAt: Date())
            let insertedMember: CommunityMember = try await client
                .from("community_members")
                .insert(member)
                .select().single().execute().value
            communityMembers.append(insertedMember)
        } catch {
            errorMessage = "Failed to create community: \(error.localizedDescription)"
        }
    }

    func joinCommunity(_ community: Community, userId: UUID) async {
        guard !isMember(communityId: community.id, userId: userId) else { return }
        let member = CommunityMember(userId: userId, communityId: community.id, role: "member", joinedAt: Date())
        do {
            let inserted: CommunityMember = try await client
                .from("community_members")
                .insert(member)
                .select().single().execute().value
            communityMembers.append(inserted)

            // Update member count
            if let index = communities.firstIndex(where: { $0.id == community.id }) {
                communities[index].memberCount += 1
                try await client
                    .from("communities")
                    .update(["member_count": communities[index].memberCount])
                    .eq("id", value: community.id.uuidString)
                    .execute()
            }
        } catch {
            errorMessage = "Failed to join community: \(error.localizedDescription)"
        }
    }

    func leaveCommunity(_ community: Community, userId: UUID) async {
        do {
            try await client
                .from("community_members")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("community_id", value: community.id.uuidString)
                .execute()

            communityMembers.removeAll { $0.communityId == community.id && $0.userId == userId }

            if let index = communities.firstIndex(where: { $0.id == community.id }) {
                communities[index].memberCount = max(0, communities[index].memberCount - 1)
                try await client
                    .from("communities")
                    .update(["member_count": communities[index].memberCount])
                    .eq("id", value: community.id.uuidString)
                    .execute()
            }
        } catch {
            errorMessage = "Failed to leave community: \(error.localizedDescription)"
        }
    }

    // MARK: - Posts
    func createPost(content: String, communityId: UUID, authorId: UUID, imageUrl: String? = nil, hashtag: String? = nil) async {
        let post = Post(
            authorId: authorId, communityId: communityId,
            content: content, imageUrl: imageUrl, hashtag: hashtag,
            likeCount: 0, createdAt: Date()
        )
        do {
            var inserted: Post = try await client
                .from("posts")
                .insert(post)
                .select().single().execute().value
            let populated = await populatePostAuthors([inserted])
            if let first = populated.first {
                inserted = first
            }
            posts.insert(inserted, at: 0)
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
        }
    }

    func deletePost(_ post: Post) async {
        do {
            try await client
                .from("posts")
                .delete()
                .eq("id", value: post.id.uuidString)
                .execute()
            posts.removeAll { $0.id == post.id }
            postComments.removeAll { $0.postId == post.id }
            postLikes.removeAll { $0.postId == post.id }
        } catch {
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
        }
    }

    func toggleLike(postId: UUID, userId: UUID) async {
        if let i = postLikes.firstIndex(where: { $0.postId == postId && $0.userId == userId }) {
            // Unlike
            let like = postLikes.remove(at: i)
            if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount = max(0, posts[j].likeCount - 1) }
            do {
                try await client
                    .from("post_likes")
                    .delete()
                    .eq("id", value: like.id.uuidString)
                    .execute()
                // Update like_count in DB
                if let j = posts.firstIndex(where: { $0.id == postId }) {
                    try await client
                        .from("posts")
                        .update(["like_count": posts[j].likeCount])
                        .eq("id", value: postId.uuidString)
                        .execute()
                }
            } catch {
                // Revert on failure
                postLikes.append(like)
                if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount += 1 }
                errorMessage = error.localizedDescription
            }
        } else {
            // Like
            let like = PostLike(userId: userId, postId: postId, createdAt: Date())
            postLikes.append(like)
            if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount += 1 }
            do {
                let inserted: PostLike = try await client
                    .from("post_likes")
                    .insert(like)
                    .select().single().execute().value
                // Replace the temp like with server-returned one (has real id)
                if let idx = postLikes.firstIndex(where: { $0.id == like.id }) {
                    postLikes[idx] = inserted
                }
                if let j = posts.firstIndex(where: { $0.id == postId }) {
                    try await client
                        .from("posts")
                        .update(["like_count": posts[j].likeCount])
                        .eq("id", value: postId.uuidString)
                        .execute()
                }
            } catch {
                // Revert
                postLikes.removeAll { $0.id == like.id }
                if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount = max(0, posts[j].likeCount - 1) }
                errorMessage = error.localizedDescription
            }
        }
    }

    func addComment(content: String, postId: UUID, userId: UUID) async {
        let comment = PostComment(
            userId: userId, postId: postId, content: content, createdAt: Date()
        )
        do {
            var inserted: PostComment = try await client
                .from("post_comments")
                .insert(comment)
                .select().single().execute().value
            let populated = await populateCommentAuthors([inserted])
            if let first = populated.first {
                inserted = first
            }
            postComments.append(inserted)
        } catch {
            errorMessage = "Failed to add comment: \(error.localizedDescription)"
        }
    }

    func deleteComment(_ comment: PostComment) async {
        do {
            try await client
                .from("post_comments")
                .delete()
                .eq("id", value: comment.id.uuidString)
                .execute()
            postComments.removeAll { $0.id == comment.id }
        } catch {
            errorMessage = "Failed to delete comment: \(error.localizedDescription)"
        }
    }

    // MARK: - Save
    func toggleSave(postId: UUID, userId: UUID) async {
        if savedPostIds.contains(postId) {
            // Unsave
            savedPostIds.remove(postId)
            do {
                try await client
                    .from("saved_posts")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("post_id", value: postId.uuidString)
                    .execute()
            } catch {
                savedPostIds.insert(postId) // revert
                errorMessage = error.localizedDescription
            }
        } else {
            // Save
            savedPostIds.insert(postId)
            let saved = SavedPost(userId: userId, postId: postId)
            do {
                try await client
                    .from("saved_posts")
                    .insert(saved)
                    .execute()
            } catch {
                savedPostIds.remove(postId) // revert
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Ownership & Dissolution
    func fetchProfiles(for userIds: [UUID]) async -> [User] {
        guard !userIds.isEmpty else { return [] }
        let idStrings = userIds.map { $0.uuidString }
        do {
            let fetched: [User] = try await client
                .from("profiles")
                .select()
                .in("id", values: idStrings)
                .execute()
                .value
            return fetched
        } catch {
            errorMessage = "Failed to fetch profiles: \(error.localizedDescription)"
            return []
        }
    }

    func transferOwnership(of community: Community, to newOwnerId: UUID) async {
        do {
            try await client
                .from("communities")
                .update(["creator_id": newOwnerId.uuidString])
                .eq("id", value: community.id.uuidString)
                .execute()

            // Try updating role in database
            _ = try? await client
                .from("community_members")
                .update(["role": "admin"])
                .eq("community_id", value: community.id.uuidString)
                .eq("user_id", value: newOwnerId.uuidString)
                .execute()

            // Update local state
            if let index = communities.firstIndex(where: { $0.id == community.id }) {
                communities[index].creatorId = newOwnerId
            }
            if let index = communityMembers.firstIndex(where: { $0.communityId == community.id && $0.userId == newOwnerId }) {
                communityMembers[index].role = "admin"
            }
        } catch {
            errorMessage = "Failed to transfer ownership: \(error.localizedDescription)"
        }
    }

    func dissolveCommunity(_ community: Community) async {
        do {
            // Delete members
            try await client
                .from("community_members")
                .delete()
                .eq("community_id", value: community.id.uuidString)
                .execute()

            // Delete posts (posts are dependent)
            try await client
                .from("posts")
                .delete()
                .eq("community_id", value: community.id.uuidString)
                .execute()

            // Delete community itself
            try await client
                .from("communities")
                .delete()
                .eq("id", value: community.id.uuidString)
                .execute()

            // Update local state
            communities.removeAll { $0.id == community.id }
            communityMembers.removeAll { $0.communityId == community.id }
            posts.removeAll { $0.communityId == community.id }
        } catch {
            errorMessage = "Failed to dissolve community: \(error.localizedDescription)"
        }
    }

    // MARK: - Post & Comment Profile Population Helpers
    func populatePostAuthors(_ postsToPopulate: [Post]) async -> [Post] {
        let authorIds = Array(Set(postsToPopulate.map { $0.authorId }))
        guard !authorIds.isEmpty else { return postsToPopulate }
        
        let profiles = await fetchProfiles(for: authorIds)
        
        return postsToPopulate.map { post in
            var updatedPost = post
            if let profile = profiles.first(where: { $0.id == post.authorId }) {
                updatedPost.authorName = profile.fullName
                updatedPost.authorImageUrl = profile.profileImageUrl
            } else {
                updatedPost.authorName = "Anonymous"
            }
            return updatedPost
        }
    }

    func populateCommentAuthors(_ commentsToPopulate: [PostComment]) async -> [PostComment] {
        let userIds = Array(Set(commentsToPopulate.map { $0.userId }))
        guard !userIds.isEmpty else { return commentsToPopulate }
        
        let profiles = await fetchProfiles(for: userIds)
        
        return commentsToPopulate.map { comment in
            var updatedComment = comment
            if let profile = profiles.first(where: { $0.id == comment.userId }) {
                updatedComment.authorName = profile.fullName
                updatedComment.authorImageUrl = profile.profileImageUrl
            } else {
                updatedComment.authorName = "Anonymous"
            }
            return updatedComment
        }
    }

    // MARK: - Image Upload (Supabase Storage)
    func uploadImage(data: Data, path: String) async throws -> String {
        // Compress if data is too large (> 2MB)
        var uploadData = data
        if uploadData.count > 2_000_000, let uiImage = UIImage(data: data) {
            uploadData = uiImage.jpegData(compressionQuality: 0.6) ?? data
        }

        try await client.storage
            .from("community-images")
            .upload(path, data: uploadData, options: .init(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage
            .from("community-images")
            .getPublicURL(path: path)
        return publicURL.absoluteString
    }
}
