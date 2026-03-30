//
//  CommunityHome.swift
//  ADHD_APP
//
//  Created by Admin on 16/03/26.
//

import SwiftUI

struct CommunityHome: View {
    @State private var addCommunity: Bool = false
    @Environment(CommunityStore.self) var communities
    var body: some View {
//        Picker(selection: )
        NavigationStack {
            
            VStack{
                ForEach(communities.communities) {
                    community in
                    CommunityRowView(community: community)
                }
                
            }
            .navigationTitle("Community")
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink{
                        ScrollView{
                            ForEach(communities.posts) {
                                post in
                                CommunityPostRowView(post: post)
                            }
                            
                        }
                        .navigationTitle("Recent Posts")
                    }
                    label: {
                        Image(systemName: "photo.on.rectangle.angled")

                            .font(.title2)
                    }
                }
                
                
                
            }
            ZStack(alignment: .bottomTrailing) {

                // Full screen background container
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    addCommunity = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.black)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.orange))
                        .shadow(radius: 5)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 10)   // keeps it above tab bar
            }
            .sheet(isPresented: $addCommunity){
                AddCommunityView(addCommunity: $addCommunity)
            }

        }
        
    }
    
    
}

    



#Preview {
    var communities = CommunityStore()
    CommunityHome()
        .environment(communities)
}
