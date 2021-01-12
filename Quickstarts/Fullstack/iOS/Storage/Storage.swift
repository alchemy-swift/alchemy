import Foundation
import PapyrusAlamofire
import Shared
import SwiftUI

typealias Tag = UserAPI.TagDTO
typealias TagColor = UserAPI.TagDTO.Color
typealias Todo = TodoAPI.TodoDTO

/// Provides central, observable repository of app data for SwiftUI
/// views to hook up to.
final class Storage: ObservableObject {
    static let shared = Storage()
    
    @Published
    var todos: [Todo] = []
    
    @Published
    var tags: [Tag] = []
    
    @Published
    var authToken: String? = nil {
        didSet {
            UserDefaults().setValue(self.authToken, forKey: "auth_token")
        }
    }
    
    init() {
        self.authToken = UserDefaults().string(forKey: "auth_token")
    }
}
