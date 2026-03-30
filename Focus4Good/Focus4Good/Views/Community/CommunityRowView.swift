//
//  CommunityRowView.swift
//  Focus4Good
//
//  Created by Admin on 16/03/26.
//

import SwiftUI

struct CommunityRowView: View {
    @State private var isJoined: Bool = false
    var community: Community

    var body: some View {
        HStack(spacing: 14) {
            // Community avatar
            ZStack {
                Circle()
                    .fill(AppTheme.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(community.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(community.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                isJoined.toggle()
            } label: {
                Text(isJoined ? "Joined" : "Join")
                    .font(.caption.bold())
                    .foregroundStyle(isJoined ? AppTheme.textSecondary : .white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(isJoined ? Color(.systemGray5) : AppTheme.orange)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
    }
}

#Preview {
    let communityObject = Community(
        creatorId: UUID(),
        name: "ADHD Community",
        description: "This community is for people who have ADHD",
        isPrivate: false,
        memberCount: 59,
        createdAt: Date()
    )
    CommunityRowView(community: communityObject)
}
