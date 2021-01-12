import SwiftUI

@main
struct QuickstartApp: App {
    @ObservedObject
    var storage = Storage.shared
    
    var body: some Scene {
        WindowGroup {
            if self.storage.authToken == nil {
                AuthView()
            } else {
                HomeView()
            }
        }
    }
}
