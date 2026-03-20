//
//  ContentView.swift
//  Focus4Good
//
//  Created by Appoorva on 20/03/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CalmCentreView()
                .tabItem {
                    Label("Calm", systemImage: "leaf")
                }
        }
        .tint(Color("CalmOrange"))
    }
}

#Preview {
    ContentView()
}
