import SwiftUI

struct CommunityRowView: View {
    var community: Community
    @Binding var selectedTab: CommunityTab
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    @State private var showUnfollowAlert = false
    @State private var showPosts = false

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID()
    }

    private var isJoined: Bool {
        communityStore.isMember(communityId: community.id, userId: currentUserId)
    }

    /// Posts belonging to this community
    private var communityPosts: [Post] {
        communityStore.posts(in: community)
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        HStack {
            // Tappable area: navigates to detail view unconditionally
            Button {
                showPosts = true
            } label: {
                communityInfo
            }
            .buttonStyle(.plain)

            Spacer()

            // Join button logic
            if !isJoined {
                Button {
                    Task {
                        await communityStore.joinCommunity(community, userId: currentUserId)
                    }
                } label: {
                    Text("Join")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(AppTheme.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            } else if selectedTab == .forYou {
                // Show a disabled 'Joined' state if they just joined while in the For You tab
                Text("Joined")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(AppTheme.orange.opacity(0.15))
                    .foregroundStyle(AppTheme.orange)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.orange, lineWidth: 1.5)
                    )
            }
        }
    }

    // MARK: - Community Info (icon + name + description)

    private var communityInfo: some View {
        HStack {
            Image(community.coverImageUrl ?? "personimage")
                .resizable()
                .scaledToFill()
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
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 10)
            .navigationDestination(isPresented: $showPosts) {
                CommunityDetailView(community: community, selectedTab: $selectedTab)
            }
        .alert("Unfollow Community", isPresented: $showUnfollowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task {
                    await communityStore.leaveCommunity(community, userId: currentUserId)
                    selectedTab = .forYou
                }
            }
        } message: {
            Text("Are you sure you want to unfollow \"\(community.name)\"? You will no longer see its posts in Your Communities.")
        }
    }
}

// MARK: - Community Posts Destination View

struct CommunityDetailView: View {
    var community: Community
    @Binding var selectedTab: CommunityTab
    
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveAlert = false
    @State private var showAddPost = false

    private var posts: [Post] {
        communityStore.posts(in: community)
    }

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID()
    }

    private var isJoined: Bool {
        communityStore.isMember(communityId: community.id, userId: currentUserId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Native Profile Header
                VStack(spacing: 12) {
                    // Avatar
                    Image(community.coverImageUrl ?? "personimage")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

                    // Name & Subtitle
                    VStack(spacing: 4) {
                        Text(community.name)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text(community.isPrivate ? "Private Community" : "Public Community")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Native-style Stats Row
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(community.memberCount)")
                                .font(.headline)
                            Text("Members")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 4) {
                            Text(community.isPrivate && !isJoined ? "—" : "\(posts.count)")
                                .font(.headline)
                            Text("Posts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

                // MARK: - About Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("ABOUT")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Text(community.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                }

                // MARK: - Posts Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("POSTS")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    if community.isPrivate && !isJoined {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("Private Community")
                                .font(.headline)
                            Text("Join this community to see its posts.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                Task {
                                    await communityStore.joinCommunity(community, userId: currentUserId)
                                }
                            } label: {
                                Text("Join")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.orange.opacity(0.4))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("No posts yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                CommunityPostRowView(post: post)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 18) {
                    if isJoined {
                        Button {
                            showAddPost = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        
                        Button {
                            showLeaveAlert = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                        }
                    } else {
                        Button {
                            Task {
                                await communityStore.joinCommunity(community, userId: currentUserId)
                            }
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }
                    }
                }
            }
        }
        .alert("Leave Community", isPresented: $showLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await communityStore.leaveCommunity(community, userId: currentUserId)
                    selectedTab = .forYou
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to leave \"\(community.name)\"?")
        }
        .sheet(isPresented: $showAddPost) {
            AddPostView(isPresented: $showAddPost, community: community)
        }
    }
}

#Preview {
    NavigationStack {
        let communityObject = Community(categoryId: nil, creatorId: UUID(), name: "ADHD Community", description: "This community is for person who having adhd", isPrivate: false, memberCount: 59, createdAt: Date())
        CommunityRowView(community: communityObject, selectedTab: .constant(.forYou))
            .environment(CommunityStore.shared)
            .environment(UserStore.shared)
    }
}
