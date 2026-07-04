import SwiftUI

enum CommunityTab: String, CaseIterable {
    case forYou = "For You"
    case yourCommunities = "Your Communities"
}

struct CommunityHome: View {
    @State private var addCommunity: Bool = false
    @State private var showRecentPosts: Bool = false
    @State private var selectedTab: CommunityTab = .forYou
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    
    @Environment(CommunityStore.self) private var communities
    @Environment(UserStore.self) private var userStore
    
    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID()
    }
    
    private var createdCommunities: [Community] {
        communities.communities.filter { $0.creatorId == currentUserId }
    }
    
    private var visibleRecentPosts: [Post] {
        communities.posts.filter { post in
            guard let community = communities.communities.first(where: { $0.id == post.communityId }) else {
                return false
            }
            if community.isPrivate {
                return community.creatorId == currentUserId || communities.isMember(communityId: community.id, userId: currentUserId)
            }
            return true
        }
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
    
    private var filteredCommunities: [Community] {
        if searchText.isEmpty {
            return []
        } else {
            return communities.communities.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Community List ──
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if !searchText.isEmpty {
                            searchResultsView
                        } else {
                            // ── Segmented Control ──
                            Picker("Tab", selection: $selectedTab) {
                                ForEach(CommunityTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            if selectedTab == .forYou {
                                forYouEmptyState
                            } else {
                                yourCommunitiesTab
                            }
                        }
                    }
                    .padding(.bottom, 80) // space for FAB
                    .animation(.default, value: forYouCommunities)
                    .animation(.default, value: joinedCommunities)
                    .animation(.default, value: selectedTab)
                    .scrollContentBackground(.hidden) // Make scroll view transparent
                }
                .background(progressBackground)
                .navigationTitle("Community")

                .searchable(text: $searchText, isPresented: $showSearch, placement: .toolbar, prompt: "Search")
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        addCommunity = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(AppTheme.buttonGradient)
                                    .shadow(color: AppTheme.orange.opacity(0.4), radius: 12, y: 6)
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 10)
                }
                .sheet(isPresented: $addCommunity) {
                    AddCommunityView(addCommunity: $addCommunity)
                }
                .navigationDestination(isPresented: $showRecentPosts) {
                    VStack(spacing: 0) {
                        ScrollView {
                            if communities.posts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.gray.opacity(0.4))
                                        .padding(.top, 40)
                                    Text("No posts available")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(communities.posts) { post in
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
                .task {
                    await communities.fetchCommunities()
                    await communities.fetchAllMembers()
                    await communities.fetchSavedPosts(userId: currentUserId)
                    for community in communities.communities {
                        await communities.fetchPosts(communityId: community.id)
                    }
                    updateSnapshot()
                }
                .onChange(of: selectedTab) { _, _ in
                    updateSnapshot()
                }
                .onChange(of: communities.communities) { _, _ in
                    updateSnapshot()
                }
                .onChange(of: communities.communityMembers) { _, _ in
                    updateSnapshot()
                }
            }
        }
    }

    private var searchResultsView: some View {
        Group {
            if filteredCommunities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray.opacity(0.4))
                        .padding(.top, 40)
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(filteredCommunities) { community in
                    CommunityRowView(community: community, selectedTab: $selectedTab)
                }
            }
        }
    }

    private var yourCommunitiesTab: some View {
        Group {
            if createdCommunities.isEmpty && joinedCommunities.isEmpty && forYouCommunities.isEmpty {
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
                
                if !forYouCommunities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for you")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, (createdCommunities.isEmpty && joinedCommunities.isEmpty) ? 0 : 8)
                        
                        ForEach(forYouCommunities) { community in
                            CommunityRowView(community: community, selectedTab: $selectedTab)
                        }
                    }
                }
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
                Text("Join communities to see them here.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.horizontal, 32)
        }
        
        // MARK: - For You Empty State (shows recent posts feed)
        private var forYouEmptyState: some View {
            VStack(spacing: 20) {

                // Recent posts from joined communities
                if !visibleRecentPosts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Posts")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                        
                        ForEach(visibleRecentPosts.prefix(5)) { post in
                            CommunityPostRowView(post: post)
                        }
                    }
                }
            }
        }
        
        // MARK: - Background
        private var progressBackground: some View {
            AppTheme.appGradient.ignoresSafeArea()
        }
    }
    
    #Preview {
        CommunityHome()
            .environment(CommunityStore.shared)
            .environment(UserStore.shared)
    }
