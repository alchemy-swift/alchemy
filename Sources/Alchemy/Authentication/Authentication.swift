import Foundation

struct BasicAuthMiddleware: Middleware {
    func intercept(_ input: Request) -> User {
        User(name: "Josh", email: "josh@gmail.com")
    }
}

struct TokenAuthMiddleware: Middleware {
    func intercept(_ input: Request) -> User {
        User(name: "Josh", email: "josh@gmail.com")
    }
}

struct User: Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String
}
