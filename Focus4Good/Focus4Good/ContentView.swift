//
//  ContentView.swift
//  Focus4Good
//
//  Created by Appoorva on 20/03/26.
//

import SwiftUI

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
#Preview {
    ContentView()
}
