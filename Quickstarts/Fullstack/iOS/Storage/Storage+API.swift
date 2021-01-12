import Foundation
import PapyrusAlamofire
import Shared

private enum API {
    static let auth = AuthAPI(baseURL: "http://localhost:8888")
    static let user = UserAPI(baseURL: "http://localhost:8888")
    static let todo = TodoAPI(baseURL: "http://localhost:8888")
}

extension Storage {
    
    // MARK: - AuthAPI
    
    func signup(name: String, email: String, password: String) {
        let request = AuthAPI.SignupRequest(.init(name: name, email: email, password: password))
        try! API.auth.signup.request(request) { response, result in
            switch result {
            case .failure(let error):
                print("Error signing up: \(error).")
            case .success(let token):
                self.authToken = token.value
            }
        }
    }
    
    func login(email: String, password: String) {
        let request = AuthAPI.LoginRequest(dto: .init(email: email, password: password))
        try! API.auth.login.request(request) { response, result in
            switch result {
            case .failure(let error):
                print("Error logging in: \(error).")
            case .success(let token):
                self.authToken = token.value
            }
        }
    }
    
    // MARK: - TodoAPI
    
    func getTodos() {
        try! API.todo.getAll.request(.value, session: .tokenSession) { response, result in
            switch result {
            case .success(let todos):
                self.todos = todos
            case .failure(let error):
                print("Error getting todos: \(error).")
            }
        }
    }
    
    func createTodo(name: String, tags: [Tag]) {
        let request = TodoAPI.CreateTodoRequest(dto: .init(name: name, tagIDs: tags.map(\.id)))
        try! API.todo.create.request(request, session: .tokenSession) { response, result in
            switch result {
            case .success(let todo):
                self.todos.append(todo)
            case .failure(let error):
                print("Error create a todo: \(error).")
            }
        }
    }
    
    func deleteTodo(_ todo: Todo) {
        let request = TodoAPI.DeleteTodoRequest(todoID: String(todo.id))
        try! API.todo.delete.request(request, session: .tokenSession) { response, result in
            switch result {
            case .success:
                self.todos.removeAll(where: { $0.id == todo.id })
            case .failure(let error):
                print("Error deleting a todo: \(error).")
            }
        }
    }
    
    func completeTodo(_ todo: Todo) {
        let request = TodoAPI.CompleteTodoRequest(todoID: String(todo.id))
        try! API.todo.complete.request(request, session: .tokenSession) { response, result in
            switch result {
            case .success(let todo):
                guard let index = self.todos.firstIndex(where: { $0.id == todo.id }) else {
                    return
                }
                
                self.todos[index] = todo
            case .failure(let error):
                print("Error completing a todo: \(error).")
            }
        }
    }
    
    // MARK: - UserAPI
    
    func createTag(name: String, color: TagColor) {
        let request = UserAPI.TagCreateRequest(dto: .init(name: name, color: color))
        try! API.user.createTag.request(request, session: .tokenSession) { response, result in
            switch result {
            case .success(let tag):
                self.tags.append(tag)
            case .failure(let error):
                print("Error create a tag: \(error).")
            }
        }
    }
    
    func getTags() {
        try! API.user.getTags.request(.value, session: .tokenSession) { response, result in
            switch result {
            case .success(let tags):
                self.tags = tags
            case .failure(let error):
                print("Error fetching tags: \(error).")
            }
        }
    }
    
    func logout() {
        try! API.user.logout.request(.value, session: .tokenSession) { response, result in
            switch result {
            case .success:
                self.authToken = nil
            case .failure(let error):
                print("Error logging out: \(error).")
            }
        }
    }
}
