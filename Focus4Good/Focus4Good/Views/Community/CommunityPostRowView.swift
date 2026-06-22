import SwiftUI

// MARK: - Time Ago Formatter

private func timeAgo(_ date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    if seconds < 60 { return "Just now" }
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes)m ago" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h ago" }
    let days = hours / 24
    if days < 7 { return "\(days)d ago" }
    let weeks = days / 7
    if weeks < 4 { return "\(weeks)w ago" }
    let months = days / 30
    if months < 12 { return "\(months)mo ago" }
    let years = days / 365
    return "\(years)y ago"
}

struct CommunityPostRowView: View {
    var post: Post
    @State private var showComments: Bool = false
    @State private var showLikesList: Bool = false
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore

    private var currentUserId: UUID? { userStore.currentUser?.id }

    private var isLiked: Bool {
        guard let uid = currentUserId else { return false }
        return communityStore.isLiked(postId: post.id, userId: uid)
    }

    private var commentCount: Int {
        communityStore.comments(for: post).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ── Author Header ──
            HStack(spacing: 12) {
                Group {
                    if let urlStr = post.authorImageUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image { img.resizable().scaledToFill() }
                            else { Image(systemName: "person.crop.circle.fill").font(.title2).foregroundStyle(.secondary) }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill").font(.title2).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .background(Circle().fill(Color(.systemGray5)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName ?? "Anonymous")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    Text(timeAgo(post.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let hashtag = post.hashtag {
                    Text("#\(hashtag)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(AppTheme.orange)
                        .background(AppTheme.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // ── Content ──
            Text(post.content)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.vertical, 2)

            // ── Post Image ──
            if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 220)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 220)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }

            // ── Like & Comment Bar ──
            HStack(spacing: 24) {
                // Likes Group (Heart Icon + Count)
                HStack(spacing: 6) {
                    // Like Button (Heart Icon)
                    Button {
                        guard let uid = currentUserId else { return }
                        Task { await communityStore.toggleLike(postId: post.id, userId: uid) }
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(isLiked ? Color.red : Color(.secondaryLabel))
                    }
                    .buttonStyle(.plain)

                    // Like Count Button (Tappable count)
                    Button {
                        if post.likeCount > 0 {
                            showLikesList = true
                        }
                    } label: {
                        Text("\(post.likeCount)")
                            .font(.subheadline)
                            .foregroundStyle(isLiked ? Color.red : Color(.secondaryLabel))
                            .fontWeight(post.likeCount > 0 ? .semibold : .regular)
                    }
                    .buttonStyle(.plain)
                    .disabled(post.likeCount == 0)
                }

                // Comment Button
                Button {
                    showComments = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(.secondaryLabel))
                        Text("\(commentCount)")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $showComments) {
            CommentsSheetView(post: post)
        }
        .sheet(isPresented: $showLikesList) {
            PostLikesSheetView(post: post)
        }
        .task {
            await communityStore.fetchLikes(postId: post.id)
        }
    }
}

// MARK: - Post Likes Sheet

struct PostLikesSheetView: View {
    let post: Post
    @Environment(CommunityStore.self) private var communityStore
    @Environment(\.dismiss) private var dismiss
    @State private var likers: [User] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if likers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.4))
                        Text("No likes yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(likers) { user in
                        HStack(spacing: 12) {
                            Group {
                                if let urlStr = user.profileImageUrl, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { phase in
                                        if let img = phase.image { img.resizable().scaledToFill() }
                                        else { Image(systemName: "person.crop.circle.fill").font(.subheadline).foregroundStyle(.secondary) }
                                    }
                                } else {
                                    Image(systemName: "person.crop.circle.fill").font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .background(Circle().fill(Color(.systemGray5)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.fullName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Likes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                isLoading = true
                await communityStore.fetchLikes(postId: post.id)
                let postLikes = communityStore.postLikes.filter { $0.postId == post.id }
                let userIds = postLikes.map { $0.userId }
                likers = await communityStore.fetchProfiles(for: userIds)
                isLoading = false
            }
        }
    }
}

// MARK: - Comments Sheet

struct CommentsSheetView: View {
    let post: Post
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    @State private var newCommentText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var currentUser: User? {
        userStore.currentUser
    }

    private var comments: [PostComment] {
        communityStore.comments(for: post)
    }

    var body: some View {
        NavigationStack {
            Group {
                if comments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 44))
                            .foregroundStyle(.gray.opacity(0.3))
                        Text("No comments yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Be the first to share your thoughts!")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(comments) { comment in
                            HStack(alignment: .top, spacing: 12) {
                                Group {
                                    if let urlStr = comment.authorImageUrl, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { phase in
                                            if let img = phase.image { img.resizable().scaledToFill() }
                                            else { Image(systemName: "person.fill").font(.subheadline).foregroundStyle(.secondary) }
                                        }
                                    } else {
                                        Image(systemName: "person.fill").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                                .background(Circle().fill(Color(.systemGray5)))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text(comment.authorName ?? "Anonymous")
                                            .font(.subheadline.bold())
                                        Text(timeAgo(comment.createdAt))
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Text(comment.content)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // ── Native Message Input Bar ──
                VStack(spacing: 0) {
                    Divider()
                    HStack(alignment: .bottom, spacing: 12) {
                        Group {
                            if let urlStr = currentUser?.profileImageUrl, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    if let img = phase.image { img.resizable().scaledToFill() }
                                    else { Image(systemName: "person.fill").font(.callout).foregroundStyle(.secondary) }
                                }
                            } else {
                                Image(systemName: "person.fill").font(.callout).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .background(Circle().fill(Color(.systemGray5)))
                        .padding(.bottom, 2)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                                .lineLimit(1...5)
                                .textFieldStyle(.plain)
                                .focused($isInputFocused)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            
                            Button {
                                guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                      let userId = currentUser?.id else { return }
                                Task {
                                    await communityStore.addComment(
                                        content: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
                                        postId: post.id,
                                        userId: userId
                                    )
                                    newCommentText = ""
                                    isInputFocused = false
                                }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.gray.opacity(0.3)
                                        : AppTheme.orange
                                    )
                            }
                            .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .padding(.bottom, 4)
                            .padding(.trailing, 4)
                        }
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await communityStore.fetchComments(postId: post.id)
            }
        }
    }
}

#Preview {
    let post = Post(
        authorId: UUID(),
        communityId: UUID(),
        content: "This is the community for ADHD where people can connect, share, and do work that will help people with ADHD.",
        hashtag: "ADHD",
        likeCount: 1023,
        createdAt: Date(),
        authorName: "Alex Johnson",
        authorImageUrl: "profilePic"
    )
    CommunityPostRowView(post: post)
        .environment(CommunityStore.shared)
        .environment(UserStore.shared)
}
