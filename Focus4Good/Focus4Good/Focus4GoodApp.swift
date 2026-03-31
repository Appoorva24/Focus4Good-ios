import SwiftUI

@main
struct Focus4GoodApp: App {

    @State private var calmStore = CalmCentreStore.shared

    var body: some Scene {
        WindowGroup {
            CalmCentreView()
                .environment(calmStore)
        }
    }
}
