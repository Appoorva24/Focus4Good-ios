//
//  CommunityPostRowView.swift
//  Focus4Good
//
//  Created by Admin on 17/03/26.
//

import SwiftUI

struct CommunityPostRowView: View {
    var post: Post
    @State private var isLiked: Bool = false
    @State private var isComment: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(AppTheme.orange.opacity(0.6))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Community Member")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(post.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()

                if let hashtag = post.hashtag {
                    Text("#\(hashtag)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.orange.opacity(0.12)))
                }
            }

            // Content
            Text(post.content)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(3)

            // Actions
            HStack(spacing: 20) {
                Button {
                    isLiked.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isLiked ? AppTheme.orange : AppTheme.textSecondary)
                        Text("\(post.likeCount + (isLiked ? 1 : 0))")
                            .font(.caption.bold())
                            .foregroundStyle(isLiked ? AppTheme.orange : AppTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    isComment.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isComment ? "message.fill" : "message")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isComment ? AppTheme.orange : AppTheme.textSecondary)
                        Text("Reply")
                            .font(.caption.bold())
                            .foregroundStyle(isComment ? AppTheme.orange : AppTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    let post = Post(
        authorId: UUID(),
        communityId: UUID(),
        content: "Just completed my first Pomodoro session without distractions! 🎉",
        hashtag: "ADHD",
        likeCount: 42,
        createdAt: Date()
    )
    CommunityPostRowView(post: post)
}
