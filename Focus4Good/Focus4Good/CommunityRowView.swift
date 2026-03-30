//
//  CommunityRowView.swift
//  ADHD_APP
//
//  Created by Admin on 16/03/26.
//

import SwiftUI

struct CommunityRowView: View {
    @State private var isJoin: Bool = false
    var community : Community
    var body: some View {
        
        HStack {
            Image("PersonImage")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(community.name)
                    .font(Font.title.bold())
                    .font(.headline)
                
                Text(community.description)
                    .font(.subheadline)
            }
            Spacer()
            Button("Join") {
                // add what happen when user click
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(.orange)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            
        }
        .padding()
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 25)
            .stroke(Color.black.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 10)
        
        
        
//        .padding(.horizontal , 4)
//        .padding(.vertical, 20)
//        .background(Color.black.opacity(0.05))
//        .clipShape(RoundedRectangle(cornerRadius: 20))
//        .padding(.horizontal, 8)
//        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 6)
    }
}

#Preview {
    let communityObject = Community(categoryId: nil, creatorId: UUID(), name: "ADHD Community", description: "This community is for person who having adhd ", isPrivate: false, memberCount: 59, createdAt: Date())
    
    CommunityRowView(community: communityObject)
}


//struct Community: Identifiable, Codable, Hashable {
//    var id: UUID = UUID()
//    var categoryId: UUID?
//    var creatorId: UUID
//    var name: String
//    var description: String
//    var coverImageUrl: String?
//    var isPrivate: Bool
//    var memberCount: Int
//    var createdAt: Date
//}
