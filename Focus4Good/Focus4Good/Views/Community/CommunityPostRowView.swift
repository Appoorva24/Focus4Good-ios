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
            HStack {
                Group {
                    if let urlStr = post.authorImageUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image { img.resizable().scaledToFill() }
                            else { Image(systemName: "person.fill").font(.title3).foregroundStyle(.secondary) }
                        }
                    } else {
                        Image(systemName: "person.fill").font(.title3).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .background(Circle().fill(Color(.systemGray5)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName ?? "Anonymous")
                        .font(.subheadline.bold())

                    Text(timeAgo(post.createdAt))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if let hashtag = post.hashtag {
                    Text("#\(hashtag)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .foregroundStyle(.blue)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // ── Content ──
            Text(post.content)
                .font(.callout)

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
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(height: 220)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    default:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(height: 220)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }

            // ── Like & Comment Bar ──
            HStack(spacing: 4) {
                Button {
                    guard let uid = currentUserId else { return }
                    Task { await communityStore.toggleLike(postId: post.id, userId: uid) }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isLiked ? AppTheme.orange : AppTheme.orange.opacity(0.5))
                }

                Text("\(post.likeCount)")
                    .foregroundStyle(isLiked ? AppTheme.orange : AppTheme.orange.opacity(0.5))

                Spacer().frame(width: 12)

                Button {
                    showComments = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.system(size: 20, weight: .bold))
                        if commentCount > 0 {
                            Text("\(commentCount)")
                                .font(.subheadline)
                        }
                    }
                    .foregroundStyle(AppTheme.orange.opacity(0.5))
                }

                Spacer()

                // ── Save Button ──
                Button {
                    guard let uid = currentUserId else { return }
                    Task { await communityStore.toggleSave(postId: post.id, userId: uid) }
                } label: {
                    let isSaved: Bool = {
                        guard let uid = currentUserId else { return false }
                        return communityStore.isSaved(postId: post.id, userId: uid)
                    }()
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isSaved ? AppTheme.orange : AppTheme.orange.opacity(0.5))
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .fullScreenCover(isPresented: $showComments) {
            CommentsSheetView(post: post)
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
