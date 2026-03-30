//
//  CommunityHome.swift
//  Focus4Good
//
//  Created by Admin on 16/03/26.
//

import SwiftUI

struct CommunityHome: View {
    @State private var addCommunity: Bool = false
    @Environment(CommunityStore.self) var communities

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 12) {
                        if communities.communities.isEmpty {
                            VStack(spacing: 16) {
                                Spacer().frame(height: 60)
                                Image(systemName: "person.3.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 72, height: 72)
                                    .foregroundStyle(AppTheme.orange.opacity(0.5))

                                Text("No communities yet")
                                    .font(.title3.bold())
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("Create or join a community to connect with others")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(communities.communities) { community in
                                CommunityRowView(community: community)
                            }
                        }
                    }
                    .padding(.bottom, 80) // Space for FAB
                }

                // Floating add button
                Button {
                    addCommunity = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(AppTheme.orange))
                        .shadow(color: AppTheme.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 16)
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(communities.posts) { post in
                                    CommunityPostRowView(post: post)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .navigationTitle("Recent Posts")
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
            .sheet(isPresented: $addCommunity) {
                AddCommunityView(addCommunity: $addCommunity)
            }
        }
    }
}

#Preview {
    let communities = CommunityStore.shared
    CommunityHome()
        .environment(communities)
}
