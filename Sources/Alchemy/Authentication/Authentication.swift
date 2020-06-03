import Foundation

public protocol Authable {}

extension Authable {
    public static func basicAuthMiddleware() -> BasicAuthMiddleware<Self> {
        BasicAuthMiddleware()
    }
    
    public static func tokenAuthMiddleware() -> TokenAuthMiddleware<Self> {
        TokenAuthMiddleware()
    }
}

public struct BasicAuthMiddleware<T: Authable>: Middleware {
    public func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
        // Load object from DB, authing via username/password
        fatalError()
    }
    
    public init() {}
}

public struct TokenAuthMiddleware<T: Authable>: Middleware {
    public func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
        // Load object from DB, authing via token
        fatalError()
    }
    
    public init() {}
}
