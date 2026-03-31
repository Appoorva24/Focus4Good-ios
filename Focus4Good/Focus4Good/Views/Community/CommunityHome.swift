import SwiftUI

enum CommunityTab: String, CaseIterable {
    case forYou           = "For You"
    case yourCommunities  = "Your Communities"
}

struct CommunityHome: View {
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self)      private var userStore

    @State private var addCommunity: Bool = false
    @State private var selectedTab: CommunityTab = .forYou

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID()
    }

    private var filteredCommunities: [Community] {
        switch selectedTab {
        case .forYou:
            return communityStore.communities
        case .yourCommunities:
            return communityStore.communities.filter {
                communityStore.isMember(communityId: $0.id, userId: currentUserId)
            }
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
                    LazyVStack(spacing: 12) {
                        if filteredCommunities.isEmpty {
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
                        } else {
                            ForEach(filteredCommunities) { community in
                                CommunityRowView(community: community)
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(communityStore.posts) { post in
                                    CommunityPostRowView(post: post)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .navigationTitle("Recent Posts")
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
                        .background(Circle().fill(AppTheme.orange))
                        .shadow(color: AppTheme.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 10)
            }
            .sheet(isPresented: $addCommunity) {
                AddCommunityView(addCommunity: $addCommunity)
            }
        }
    }
}

#Preview {
    CommunityHome()
        .environment(CommunityStore.shared)
        .environment(UserStore.shared)
}
