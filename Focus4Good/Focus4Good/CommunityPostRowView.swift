//
//  CommunityPostRowView.swift
//  ADHD_APP
//
//  Created by Admin on 17/03/26.
//

import SwiftUI

struct CommunityPostRowView: View {
    var post : Post
    @State private var isClicked: Bool = false
    @State private var isComment: Bool = false
    var body: some View {
        NavigationStack{
            VStack(alignment: .leading) {
                HStack {
                    Image(post.imageUrl ?? "profilePic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(4)
                    
                    VStack(alignment: .leading){
                        Text(post.content)
                            .font(.headline)
//                        Text(timeAgo(from: post.postTime))
//                            .font(.caption)
//                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    VStack {
                        if let hashtag = post.hashtag {
                            Text("#\(hashtag)")
                                .padding()
                                .frame(height: 22)
                                .font(.caption)
                                .foregroundStyle(Color.blue)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                        
                        
                            
                        
                    }
                    
                    
                }
                
                Text(post.content)
                    .font(.callout)
                    .padding(.vertical, 10)
                
                Image("FirstPost")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(16)
                
                HStack {
                    Button{
                        if isClicked {
                            
                        }
                        isClicked.toggle()
                    }
                    label:{
                        
                        
                        if isClicked {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.orange.opacity(1))
                                .font(Font.system(size: 20, weight: .bold))
                                .padding(5)
                            
                            
                        }
                        else{
                            Image(systemName: "heart")
                                .foregroundStyle(Color.orange.opacity(1))
                                .font(Font.system(size: 20, weight: .bold))
                                .padding(5)
                            
                                .foregroundStyle(Color.black.opacity(0.5))
                        }
                        
                        
                    }
                    Text("\(post.likeCount)")
                    //                    .font()
                        .foregroundStyle(isClicked ? Color.orange.opacity(2) : Color.orange.opacity(0.5))
                    Button{
                        if isComment {
                            
                        }
                        isComment.toggle()
                    }
                    label:{
                        
                        
                        if isComment {
                            Image(systemName: "message.fill")
                                .foregroundStyle(Color.orange.opacity(1))
                                .font(Font.system(size: 20, weight: .bold))
                                .padding(5)
                            
                            
                        }
                        else{
                            Image(systemName: "message")
                                .foregroundStyle(Color.orange.opacity(1))
                                .font(Font.system(size: 20, weight: .bold))
                                .padding(5)
                            
                                .foregroundStyle(Color.black.opacity(0.5))
                        }
                        
                        
                    }
//                    Text("\(post.)")
//                    //                    .font()
//                        .foregroundStyle(isComment ? Color.orange.opacity(2) : Color.orange.opacity(0.5))
                    
                    
                }
                
            }
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            
        }
    }
}

#Preview {
    var postLike = PostLike(userId: UUID(), postId: UUID(), createdAt: Date())
    
    var postComment = PostComment(userId: UUID(), postId: UUID(), content: "Great Word!", createdAt: Date())
    
    var post = Post(authorId: UUID(), communityId: UUID(), content: "This is the community for adhd where people can connect share and do work that will help for people having adhd.", imageUrl: nil, hashtag: "ADHD", likeCount: 1023, createdAt: Date())
    CommunityPostRowView(post: post)
        
}

//struct Post: Identifiable, Codable, Hashable {
//    var id: UUID = UUID()
//    var authorId: UUID
//    var communityId: UUID
//    var content: String
//    var imageUrl: String?
//    var hashtag: String?
//    var likeCount: Int
//    var createdAt: Date
//}
//
//// MARK: - PostLike
//struct PostLike: Identifiable, Codable, Hashable {
//    var id: UUID = UUID()
//    var userId: UUID
//    var postId: UUID
//    var createdAt: Date
//}
//
//// MARK: - PostComment
//struct PostComment: Identifiable, Codable, Hashable {
//    var id: UUID = UUID()
//    var userId: UUID
//    var postId: UUID
//    var content: String
//    var createdAt: Date
//}
