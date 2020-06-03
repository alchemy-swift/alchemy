import Crypto
import Foundation

public protocol TokenAuthable: Model {
    associatedtype User: Model
    
    static var valueKeyString: String { get }
    static var userKey: KeyPath<Self, Self.BelongsTo<User>> { get }
}

extension TokenAuthable {
    public static var valueKeyString: String { "value" }
    
    public static func tokenAuthMiddleware() -> TokenAuthMiddleware<Self> {
        TokenAuthMiddleware()
    }
}

public struct TokenAuthMiddleware<T: TokenAuthable>: Middleware {
    public func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
        catchError {
            guard let bearerAuth = request.bearerAuth() else {
                throw HTTPError(.unauthorized)
            }
            
            return T.query()
                .where(T.valueKeyString == bearerAuth.token)
                .with(T.userKey)
                .getFirst()
                .map { request.set($0[keyPath: T.userKey]) }
        }
    }
}
