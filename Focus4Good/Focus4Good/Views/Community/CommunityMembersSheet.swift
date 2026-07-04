import SwiftUI

struct CommunityMemberRow: Identifiable {
    let id: UUID // user id
    let name: String
    let email: String
    let imageUrl: String?
    let role: String
}

struct CommunityMembersSheet: View {
    let community: Community
    @Environment(CommunityStore.self) private var communityStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var memberRows: [CommunityMemberRow] = []
    @State private var isLoading = false
    @State private var searchField = ""
    
    var filteredRows: [CommunityMemberRow] {
        if searchField.isEmpty {
            return memberRows
        } else {
            return memberRows.filter { $0.name.localizedCaseInsensitiveContains(searchField) || $0.email.localizedCaseInsensitiveContains(searchField) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading members...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if memberRows.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.4))
                        Text("No members found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredRows) { row in
                            HStack {
                                Group {
                                    if let urlStr = row.imageUrl, let url = URL(string: urlStr) {
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
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.name)
                                        .font(.body.bold())
                                        .foregroundStyle(.primary)
                                    Text(row.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // Role Badge
                                let displayRole: String = {
                                    if row.id == community.creatorId { return "Owner" }
                                    return row.role.capitalized
                                }()
                                
                                Text(displayRole)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .foregroundStyle(displayRole == "Owner" || displayRole == "Admin" ? .white : .secondary)
                                    .background(
                                        Capsule()
                                            .fill(displayRole == "Owner" || displayRole == "Admin" ? AppTheme.orange : Color(.systemGray4))
                                    )
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchField, prompt: "Search members")
                }
            }
            .navigationTitle("Members")
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
                await fetchAndBuildMembers()
                isLoading = false
            }
        }
    }
    
    private func fetchAndBuildMembers() async {
        let members = communityStore.communityMembers.filter { $0.communityId == community.id }
        guard !members.isEmpty else { return }
        
        let ids = members.map { $0.userId }
        let profiles = await communityStore.fetchProfiles(for: ids)
        
        var tempRows: [CommunityMemberRow] = []
        for member in members {
            if let profile = profiles.first(where: { $0.id == member.userId }) {
                tempRows.append(CommunityMemberRow(
                    id: profile.id,
                    name: profile.fullName,
                    email: profile.email,
                    imageUrl: profile.profileImageUrl,
                    role: member.role
                ))
            }
        }
        
        // Sort: Owner -> Admin -> Member Name
        memberRows = tempRows.sorted { r1, r2 in
            let isOwner1 = r1.id == community.creatorId
            let isOwner2 = r2.id == community.creatorId
            if isOwner1 != isOwner2 { return isOwner1 }
            
            let isAdmin1 = r1.role == "admin"
            let isAdmin2 = r2.role == "admin"
            if isAdmin1 != isAdmin2 { return isAdmin1 }
            
            return r1.name.localizedCompare(r2.name) == .orderedAscending
        }
    }
}
