import Foundation
import Shared
import SwiftUI

typealias Tag = UserAPI.TagDTO
typealias Todo = TodoAPI.TodoDTO

final class Storage: ObservableObject {
    static let shared = Storage()
    
    @Published
    var todos: [Todo] = []
    
    @Published
    var tags: [Tag] = []
    
    @Published
    var authToken: String? = nil
}

enum API {
    static let auth = AuthAPI(baseURL: "http://localhost:8888")
    static let user = UserAPI(baseURL: "http://localhost:8888")
    static let todo = TodoAPI(baseURL: "http://localhost:8888")
}

extension Storage {
    func signup(name: String, email: String, password: String) {
        API.auth.
    }
    
    func login(email: String, password: String) {
        
    }
    
    func getTodos() {
        
    }
    
    func createTodo() {
        
    }
    
    func deleteTodo() {
        
    }
    
    func createTag() {
        
    }
    
    func getTags() {
        
    }
}
