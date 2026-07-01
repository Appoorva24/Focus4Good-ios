import SwiftUI

enum CommunityTab: String, CaseIterable {
    case forYou = "For You"
    case yourCommunities = "Your Communities"
}

struct CommunityHome: View {
    @State private var addCommunity: Bool = false
    @State private var showRecentPosts: Bool = false
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
                                forYouEmptyState
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
                .scrollContentBackground(.hidden) // Make scroll view transparent
            }
            .background(progressBackground)
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

    // MARK: - For You Empty State (shows recent posts feed)
    private var forYouEmptyState: some View {
        VStack(spacing: 20) {
            // Recent Activity Header
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.orange)

                Text("Your Community Feed")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.warmTextPrimary)

                Text("Here's what's happening in your communities")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // Recent posts from joined communities
            if !communities.posts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Posts")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)

                    ForEach(communities.posts.prefix(5)) { post in
                        CommunityPostRowView(post: post)
                    }
                }
            }

            // Create Community Card
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.orange)

                Text("Start Your Own Community")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.warmTextPrimary)

                Text("Create a space for people to connect and share.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    addCommunity = true
                } label: {
                    Text("Create Community")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(AppTheme.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), AppTheme.cardGradientEnd],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: AppTheme.orange.opacity(0.10), radius: 10, y: 3)
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Background with wave decorations
    private var progressBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.pageBgTop,
                    AppTheme.pageBgMid,
                    AppTheme.pageBgBot
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                WaveShape()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.orange.opacity(0.10), AppTheme.orange.opacity(0.18)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 140)
                    .ignoresSafeArea(edges: .bottom)

                WaveShape()
                    .fill(AppTheme.orange.opacity(0.06))
                    .frame(height: 80)
                    .offset(y: -40)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Wave Shape (Background decoration)
private struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h * 0.4))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.3),
            control1: CGPoint(x: w * 0.3, y: 0),
            control2: CGPoint(x: w * 0.7, y: h * 0.8)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

#Preview {
    CommunityHome()
        .environment(CommunityStore.shared)
        .environment(UserStore.shared)
}
