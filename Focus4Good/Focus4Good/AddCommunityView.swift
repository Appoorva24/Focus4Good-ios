//
//  AddCommunityView.swift
//  ADHD_APP
//
//  Created by Admin on 17/03/26.
//

import SwiftUI

struct AddCommunityView: View {
    @Binding var addCommunity: Bool
    @State private var nameOfCommunity: String = ""
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var isPrivate: Bool = false
    var body: some View {
        NavigationStack {
                VStack() {
                    VStack{
                        Image("PersonImage")
                            .resizable()
                            .scaledToFit()
                        
                            .frame(width: 100, height: 100)
                        
                            .padding()
                            
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            
                        
                        
                        
                        Button{
                            
                        }
                        label:{
                            Text("Add Cover Photo")
                                .foregroundStyle(Color.orange)
                        }
                    }
                    
                    
                    VStack(spacing: 0) {
                        HStack() {
                            Text("Name")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            
                            Spacer()
                            
                            TextField("Community Name", text: $nameOfCommunity)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.gray)
                            
                        }
                        .padding()
                        Divider()
                        
                        
                        HStack {
                            Text("Category").font(.headline)
                            Spacer()
                            Button{
                                
                            }
                            label:{
                                Text("Select")
                                    .foregroundStyle(.gray)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            
                        }
                        .padding()
                        Divider()
                        
                        VStack(alignment: .leading){
                            
                            TextEditor( text: $description)
                                .frame(height: 120)
                                .background(Color.gray.opacity(1))
                                
                        }
                        .padding()
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(1.0), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                VStack(spacing: 0){
                    HStack {
                        Toggle(isOn: $isPrivate){
                            Text("Private Community")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                }
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(1.0), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    
                    
                    
                    
                    
                    NavigationLink{
                        
                    }
                    label:{
                        Text("Create Community")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                            .frame(width: 380, height: 40)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .padding()
                    
                    
                    
                   Spacer()
                    
                }
                
                
                .navigationBarTitle("Add Community")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem(placement: .topBarLeading) {
                        Button(){
                            addCommunity = false
                        }
                        label:{
                            Text("Cancel")
                        }
                    }
                    
                    
                }
            
        }
    }
}

#Preview {
    AddCommunityView(addCommunity: .constant(true))
}
