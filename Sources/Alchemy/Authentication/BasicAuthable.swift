public protocol BasicAuthable: Model {
    static var usernameKeyString: String { get }
    static var passwordHashKeyString: String { get }
    
    static func verify(password: String, passwordHash: String) throws -> Bool
}

extension BasicAuthable {
    public static var usernameKeyString: String { "username" }
    public static var passwordHashKeyString: String { "password_hash" }
    
    public static func verify(password: String, passwordHash: String) throws -> Bool {
        try Bcrypt.verify(password, created: passwordHash)
    }
    
    public static func basicAuthMiddleware() -> BasicAuthMiddleware<Self> {
        BasicAuthMiddleware()
    }
}

public struct BasicAuthMiddleware<B: BasicAuthable>: Middleware {
    public func intercept(_ request: HTTPRequest) -> EventLoopFuture<HTTPRequest> {
        catchError {
            guard let basicAuth = request.basicAuth() else {
                throw HTTPError(.unauthorized)
            }
            
            return B.query()
                .where(B.usernameKeyString == basicAuth.username)
                .get(["\(B.tableName).*", B.passwordHashKeyString])
                .flatMapThrowing { rows -> B in
                    guard let firstRow = rows.first else {
                        throw HTTPError(.unauthorized)
                    }
                    
                    let passwordHash = try firstRow.getField(columnName: B.passwordHashKeyString).string()
                    
                    guard try B.verify(password: basicAuth.password, passwordHash: passwordHash) else {
                        throw HTTPError(.unauthorized)
                    }
                    
                    return try firstRow.decode(B.self)
                }
                .map { request.set($0) }
        }
    }
}
