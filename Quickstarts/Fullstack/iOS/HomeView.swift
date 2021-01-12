import Foundation
import SwiftUI

struct HomeView: View {
    @ObservedObject
    var storage = Storage.shared
    
    var body: some View {
        List(self.storage.todos) { todo in
            Text(todo.name)
        }
    }
}
