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
    @State private var isCommented: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── Author Header ──
            HStack {
                Image(post.authorImageUrl ?? "profilePic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.subheadline.bold())

                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if let hashtag = post.hashtag {
                    Text("#\(hashtag)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .foregroundStyle(.blue)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(10)
                }
            }

            // ── Content ──
            Text(post.content)
                .font(.callout)

            // ── Post Image ──
            if let postImage = post.postImageName {
                Image(postImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(16)
            }

            // ── Like & Comment Bar ──
            HStack(spacing: 4) {
                Button {
                    isLiked.toggle()
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isLiked ? AppTheme.orange : AppTheme.orange.opacity(0.5))
                }

                Text("\(post.likeCount + (isLiked ? 1 : 0))")
                    .foregroundStyle(isLiked ? AppTheme.orange : AppTheme.orange.opacity(0.5))

                Spacer().frame(width: 12)

                Button {
                    isCommented.toggle()
                } label: {
                    Image(systemName: isCommented ? "message.fill" : "message")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isCommented ? AppTheme.orange : AppTheme.orange.opacity(0.5))
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

#Preview {
    let post = Post(
        authorId: UUID(),
        authorName: "Alex Johnson",
        authorImageUrl: "profilePic",
        communityId: UUID(),
        content: "This is the community for ADHD where people can connect, share, and do work that will help people with ADHD.",
        postImageName: "FirstPost",
        hashtag: "ADHD",
        likeCount: 1023,
        createdAt: Date()
    )
    CommunityPostRowView(post: post)
}


