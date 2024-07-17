import HummingbirdCore

public struct HTTPConfiguration: Plugin {
    static let defaultHost = "127.0.0.1"
    static let defaultPort = 3000
    
    /// The default hashing algorithm.
    public let defaultHashAlgorithm: HashAlgorithm
    /// Maximum upload size allowed.
    public let maxUploadSize: Int

    public init(
        defaultHashAlgorithm: HashAlgorithm = .bcrypt,
        maxUploadSize: Int = 2 * 1024 * 1024
    ) {
        self.defaultHashAlgorithm = defaultHashAlgorithm
        self.maxUploadSize = maxUploadSize
    }
    
    public func boot(app: Application) {
        
        // 0. Register Router

        app.container.register(HTTPRouter()).singleton()
        app.container.register { $0.require() as HTTPRouter as Router }
        
        // 1. Register Handler

        app.container.register { HTTPHandler(maxUploadSize: maxUploadSize, router: $0.require() as HTTPRouter) }.singleton()
        app.container.register { $0.require() as HTTPHandler as RequestHandler }
        
        // 2. Register Client

        app.container.register(Client()).singleton()
        
        // 3. Register Hasher

        app.container.register(Hasher(algorithm: defaultHashAlgorithm)).singleton()
    }

    public func shutdown(app: Application) async throws {
        try app.container.resolve(Client.self)?.shutdown()
    }
}
