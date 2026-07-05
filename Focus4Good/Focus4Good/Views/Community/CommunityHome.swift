import SwiftUI

struct CommunityHome: View {
    @State private var addCommunity: Bool = false
    @State private var showRecentPosts: Bool = false
    @State private var showSavedPosts: Bool = false
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    @State private var selectedSavedPostCategory: String? = nil
    @State private var selectedRecentPostCategory: String? = nil
    @State private var showJoinOptions: Bool = false
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var showMicError: Bool = false
    
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
            return community.creatorId == currentUserId || communities.isMember(communityId: community.id, userId: currentUserId)
        }
    }
    
    private var recentPostCategories: [String] {
        let tags = visibleRecentPosts.compactMap { $0.hashtag }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }
    
    private var savedPostsList: [Post] {
        communities.posts.filter { communities.isSaved(postId: $0.id, userId: currentUserId) }
    }
    
    private var savedPostCategories: [String] {
        let tags = savedPostsList.compactMap { $0.hashtag }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
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
                    // Custom Native-style Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color(.secondaryLabel))
                            .font(.system(size: 17))
                        
                        TextField("Search", text: $searchText)
                            .font(.system(size: 17))
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color(.label))
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                                    .font(.system(size: 17))
                            }
                        } else {
                            // Mic button — tappable, animates when active
                            Button {
                                if speechRecognizer.isListening {
                                    speechRecognizer.stopListening()
                                } else {
                                    speechRecognizer.transcript = ""
                                    speechRecognizer.startListening()
                                }
                            } label: {
                                Image(systemName: speechRecognizer.isListening ? "waveform" : "mic.fill")
                                    .foregroundStyle(speechRecognizer.isListening ? AppTheme.orange : Color(.secondaryLabel))
                                    .font(.system(size: 17))
                                    .symbolEffect(.pulse, isActive: speechRecognizer.isListening)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 36)
                    .background(Color(UIColor.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .onChange(of: speechRecognizer.transcript) { _, newValue in
                        if !newValue.isEmpty {
                            searchText = newValue
                        }
                    }
                    .onChange(of: speechRecognizer.errorMessage) { _, error in
                        if error != nil { showMicError = true }
                    }
                    .alert("Microphone Error", isPresented: $showMicError) {
                        Button("OK", role: .cancel) { speechRecognizer.errorMessage = nil }
                    } message: {
                        Text(speechRecognizer.errorMessage ?? "")
                    }
                    
                    LazyVStack(spacing: 16) {
                        if !searchText.isEmpty {
                            searchResultsView
                        } else {
                            yourCommunitiesTab
                        }
                    }
                    .padding(.bottom, 80) // space for FAB
                    .animation(.default, value: forYouCommunities)
                    .animation(.default, value: joinedCommunities)
                    .scrollContentBackground(.hidden) // Make scroll view transparent
                }
                .background(progressBackground)
                .navigationTitle("Community")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                let now = Date().timeIntervalSince1970
                                let joined = communities.communities.filter {
                                    $0.creatorId == currentUserId || communities.isMember(communityId: $0.id, userId: currentUserId)
                                }
                                for community in joined {
                                    UserDefaults.standard.set(now, forKey: "last_visited_\(community.id.uuidString)")
                                }
                                showRecentPosts = true
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "newspaper")
                                        .foregroundStyle(AppTheme.orange)
                                        .padding(.trailing, 4) // Make space for the badge
                                    
                                    let unreadRecentPostsCount = visibleRecentPosts.filter { post in
                                        let key = "last_visited_\(post.communityId.uuidString)"
                                        return post.createdAt.timeIntervalSince1970 > UserDefaults.standard.double(forKey: key)
                                    }.count
                                    
                                    if unreadRecentPostsCount > 0 {
                                        Text(unreadRecentPostsCount > 9 ? "9+" : "\(unreadRecentPostsCount)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.orange)
                                            .clipShape(Capsule())
                                            .offset(x: 4, y: -4)
                                    }
                                }
                            }
                            
                            Button {
                                showSavedPosts = true
                            } label: {
                                Image(systemName: "bookmark")
                                    .foregroundStyle(AppTheme.orange)
                            }
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
                            let filtered = selectedRecentPostCategory == nil ? visibleRecentPosts : visibleRecentPosts.filter { $0.hashtag == selectedRecentPostCategory }
                            if filtered.isEmpty {
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
                                    ForEach(filtered) { post in
                                        CommunityPostRowView(post: post)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                    .background(progressBackground)
                    .navigationTitle("Posts")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    selectedRecentPostCategory = nil
                                } label: {
                                    HStack {
                                        Text("All")
                                        if selectedRecentPostCategory == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(recentPostCategories, id: \.self) { category in
                                    Button {
                                        selectedRecentPostCategory = category
                                    } label: {
                                        HStack {
                                            Text(category)
                                            if selectedRecentPostCategory == category {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundStyle(AppTheme.orange)
                            }
                        }
                    }
                }
                .navigationDestination(isPresented: $showSavedPosts) {
                    VStack(spacing: 0) {
                        ScrollView {
                            let filtered = selectedSavedPostCategory == nil ? savedPostsList : savedPostsList.filter { $0.hashtag == selectedSavedPostCategory }
                            if filtered.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bookmark.slash")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.gray.opacity(0.4))
                                        .padding(.top, 40)
                                    Text("No saved posts")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(filtered) { post in
                                        CommunityPostRowView(post: post)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                    .background(progressBackground)
                    .navigationTitle("Saved Posts")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    selectedSavedPostCategory = nil
                                } label: {
                                    HStack {
                                        Text("All")
                                        if selectedSavedPostCategory == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(savedPostCategories, id: \.self) { category in
                                    Button {
                                        selectedSavedPostCategory = category
                                    } label: {
                                        HStack {
                                            Text(category)
                                            if selectedSavedPostCategory == category {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundStyle(AppTheme.orange)
                            }
                        }
                    }
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
                    CommunityRowView(community: community)
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
                            CommunityRowView(community: community)
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
                            CommunityRowView(community: community)
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
                            CommunityRowView(community: community)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // ── Floating Illustration ──
                ZStack {
                    // Background glow
                    Circle()
                        .fill(AppTheme.orange.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                    
                    // Central large icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.orange, AppTheme.orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: AppTheme.orange.opacity(0.4), radius: 20, y: 8)
                        
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                    
                    // Top-left floating badge
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.orange)
                    }
                    .offset(x: -85, y: -55)
                    
                    // Top-right floating badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.indigo.opacity(0.3), radius: 8, y: 4)
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 90, y: -60)
                    
                    // Bottom-left floating badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.85), Color.teal],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 52, height: 52)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    .offset(x: -100, y: 50)
                    
                    // Bottom-right concentric rings (like Activity rings)
                    ZStack {
                        Circle()
                            .stroke(AppTheme.orange.opacity(0.3), lineWidth: 6)
                            .frame(width: 56, height: 56)
                        Circle()
                            .stroke(Color.pink.opacity(0.5), lineWidth: 6)
                            .frame(width: 42, height: 42)
                        Circle()
                            .stroke(Color.blue.opacity(0.5), lineWidth: 6)
                            .frame(width: 28, height: 28)
                    }
                    .offset(x: 92, y: 55)
                }
                .frame(height: 260)
                .padding(.top, 40)
                
                // ── Title & Description ──
                VStack(spacing: 16) {
                    Text("Join Your Community")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Connect with others on the same journey. Share progress, find motivation, and grow together — all in one place.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 32)
                .padding(.horizontal, 32)
                
                // ── Privacy Note ──
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.2.shield.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.orange)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Safe & Supportive Space")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Communities are moderated and designed to be welcoming. You control what you share and who sees it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                // ── CTA Button ──
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showJoinOptions = true
                    }
                } label: {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.orange, AppTheme.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.orange.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .overlay {
            if showJoinOptions {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showJoinOptions = false
                        }
                    }
                
                // Centered card
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.orange.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 28))
                                .foregroundStyle(AppTheme.orange)
                        }
                        Text("Join or Create")
                            .font(.title2.weight(.bold))
                        Text("How would you like to get started?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    Divider()
                    
                    // Join an existing community
                    Button {
                        withAnimation {
                            showJoinOptions = false
                        }
                        // TODO: Navigate to community browser / search
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.blue)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Join a Community")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Browse and join existing groups")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 80)
                    
                    // Create a new community
                    Button {
                        withAnimation {
                            showJoinOptions = false
                        }
                        addCommunity = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.orange.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(AppTheme.orange)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Create a Community")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Start your own group from scratch")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                    
                    // Cancel
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showJoinOptions = false
                        }
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 30, y: 10)
                .padding(.horizontal, 28)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
    }
        
        // MARK: - For You Empty State (shows recent posts feed)
        private var forYouEmptyState: some View {
            VStack(spacing: 20) {

                // Recent posts from joined communities
                if !visibleRecentPosts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Posts")
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
