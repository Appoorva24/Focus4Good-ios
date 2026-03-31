import SwiftUI

struct CommunityRowView: View {
    var community: Community
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self)      private var userStore
    @State private var showUnfollowAlert = false

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID()
    }

    private var isJoined: Bool {
        communityStore.isMember(communityId: community.id, userId: currentUserId)
    }

    private var communityPosts: [Post] {
        communityStore.posts(in: community)
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        HStack {
            if isJoined {
                NavigationLink {
                    CommunityPostsView(community: community)
                } label: {
                    communityInfo
                }
                .buttonStyle(.plain)
            } else {
                communityInfo
            }

            Spacer()

            Button {
                if isJoined {
                    showUnfollowAlert = true
                } else {
                    Task {
                        await communityStore.joinCommunity(community, userId: currentUserId)
                    }
                }
            } label: {
                Text(isJoined ? "Joined" : "Join")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(isJoined ? AppTheme.orange.opacity(0.15) : AppTheme.orange)
                    .foregroundStyle(isJoined ? AppTheme.orange : Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.orange, lineWidth: isJoined ? 1.5 : 0)
                    )
            }
        }
    }

    // MARK: - Community Info

    private var communityInfo: some View {
        HStack {
            Image("PersonImage")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(community.name)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text(community.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    var body: some View {
        cardContent
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .cornerRadius(20)
            .padding(.horizontal, 10)
            .alert("Unfollow Community", isPresented: $showUnfollowAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    Task {
                        await communityStore.leaveCommunity(community, userId: currentUserId)
                    }
                }
            } message: {
                Text("Are you sure you want to unfollow \"\(community.name)\"? You will no longer see its posts in Your Communities.")
            }
    }
}

// MARK: - Community Posts Destination

struct CommunityPostsView: View {
    var community: Community
    @Environment(CommunityStore.self) private var communityStore

    private var posts: [Post] {
        communityStore.posts(in: community)
    }

    var body: some View {
        ScrollView {
            if posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("No posts yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Be the first to share something in this community!")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 80)
                .padding(.horizontal, 32)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        CommunityPostRowView(post: post)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(community.name)
    }
}

#Preview {
    NavigationStack {
        let community = Community(
            categoryId: nil,
            creatorId: UUID(),
            name: "ADHD Community",
            description: "This community is for people who have ADHD",
            isPrivate: false,
            memberCount: 59,
            createdAt: Date()
        )
        CommunityRowView(community: community)
            .environment(CommunityStore.shared)
            .environment(UserStore.shared)
    }
}
