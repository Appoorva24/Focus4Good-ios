import SwiftUI

enum CommunityTab: String, CaseIterable {
    case forYou = "For You"
    case yourCommunities = "Your Communities"
}

enum PostFilterTab: String, CaseIterable {
    case allPosts = "Recent Posts"
    case savedPosts = "Saved Posts"
}

struct CommunityHome: View {
    @State private var addCommunity: Bool = false
    @State private var showRecentPosts: Bool = false
    @State private var postFilter: PostFilterTab = .allPosts
    @State private var selectedTab: CommunityTab = .forYou

    @Environment(CommunityStore.self) private var communities
    @Environment(UserStore.self) private var userStore

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID()
    }

    private var createdCommunities: [Community] {
        communities.communities.filter { $0.creatorId == currentUserId }
    }

    private var joinedCommunities: [Community] {
        communities.communities.filter { 
            $0.creatorId != currentUserId && communities.isMember(communityId: $0.id, userId: currentUserId)
        }
    }

    @State private var joinedIdsSnapshot: Set<UUID> = []
    @State private var hasInitializedSnapshot = false

    private func updateSnapshot() {
        joinedIdsSnapshot = Set(communities.communities.filter { 
            communities.isMember(communityId: $0.id, userId: currentUserId) || $0.creatorId == currentUserId
        }.map { $0.id })
    }

    private var forYouCommunities: [Community] {
        communities.communities.filter { 
            !joinedIdsSnapshot.contains($0.id)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Segmented Control ──
                Picker("Tab", selection: $selectedTab) {
                    ForEach(CommunityTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // ── Community List ──
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if selectedTab == .forYou {
                            if forYouCommunities.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.green.opacity(0.8))
                                    Text("You're all caught up!")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    Text("You've joined all available communities.")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 60)
                                .padding(.horizontal, 32)
                            } else {
                                ForEach(forYouCommunities) { community in
                                    CommunityRowView(community: community, selectedTab: $selectedTab)
                                }
                            }
                        } else {
                            // "Your Communities" Tab
                            if createdCommunities.isEmpty && joinedCommunities.isEmpty {
                                emptyStateView
                            } else {
                                if !createdCommunities.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Created by You")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .padding(.horizontal, 16)
                                        
                                        ForEach(createdCommunities) { community in
                                            CommunityRowView(community: community, selectedTab: $selectedTab)
                                        }
                                    }
                                }
                                
                                if !joinedCommunities.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Joined Communities")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .padding(.horizontal, 16)
                                            .padding(.top, createdCommunities.isEmpty ? 0 : 8)
                                        
                                        ForEach(joinedCommunities) { community in
                                            CommunityRowView(community: community, selectedTab: $selectedTab)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 80) // space for FAB
                    .animation(.default, value: forYouCommunities)
                    .animation(.default, value: joinedCommunities)
                    .animation(.default, value: selectedTab)
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRecentPosts = true
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    addCommunity = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(AppTheme.orange.opacity(0.8)))
                        .shadow(radius: 5)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 10)
            }
            .sheet(isPresented: $addCommunity) {
                AddCommunityView(addCommunity: $addCommunity)
            }
            .navigationDestination(isPresented: $showRecentPosts) {
                VStack(spacing: 0) {
                    Picker("Filter", selection: $postFilter) {
                        ForEach(PostFilterTab.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    ScrollView {
                        let filteredPosts = postFilter == .allPosts ? communities.posts : communities.posts.filter {
                            communities.isSaved(postId: $0.id, userId: currentUserId)
                        }
                        
                        if filteredPosts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bookmark.slash")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray.opacity(0.4))
                                    .padding(.top, 40)
                                Text(postFilter == .savedPosts ? "No saved posts yet" : "No posts available")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredPosts) { post in
                                    CommunityPostRowView(post: post)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .navigationTitle("Recent Posts")
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                if !hasInitializedSnapshot {
                    updateSnapshot()
                    hasInitializedSnapshot = true
                }
            }
            .onChange(of: selectedTab) { _, _ in
                updateSnapshot()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundStyle(.gray.opacity(0.4))
            Text("No communities yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Join communities from the \"For You\" tab to see them here.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }
}

#Preview {
    CommunityHome()
        .environment(CommunityStore.shared)
        .environment(UserStore.shared)
}
