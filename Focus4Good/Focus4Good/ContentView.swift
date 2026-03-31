import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CalmCentreView()
                .tabItem {
                    Label("Calm", systemImage: "leaf")
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
}
