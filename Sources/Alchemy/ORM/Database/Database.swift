import PostgresKit

public protocol Database: class {
    associatedtype Kind
    var pool: ConnectionPool? { get set }
}

public struct DatabaseConfig {
    public enum Socket {
        case ipAddress(host: String, port: Int)
        case unixSocket(path: String)
    }
    
    public let socket: Socket
    public let database: String
    public let username: String
    public let password: String
    
    public init(
        socket: Socket,
        database: String,
        username: String,
        password: String
    ) {
        self.socket = socket
        self.database = database
        self.username = username
        self.password = password
    }
}

extension Database {
    var isConfigured: Bool { self.pool != nil }
    
    public func configure(with config: DatabaseConfig, eventLoopGroup: EventLoopGroup) {
        print("Configuring.")
        //  Initialize the pool.
        let postgresConfig: PostgresConfiguration
        switch config.socket {
        case .ipAddress(let host, let port):
            postgresConfig = .init(
                hostname: host,
                port: port,
                username: config.username,
                password: config.password,
                database: config.database
            )
        case .unixSocket(let name):
            postgresConfig = .init(
                unixDomainSocketPath: name,
                username: config.username,
                password: config.password,
                database: config.database
            )
        }
        
        let pool = EventLoopGroupConnectionPool(
            source: PostgresConnectionSource(configuration: postgresConfig),
            on: eventLoopGroup
        )
        
        self.pool = pool
    }
    
    public func shutdown() {
        self.pool?.shutdown()
    }
    
    public func test(on el: EventLoop) -> EventLoopFuture<String> {
        return self.query("SELECT version()", on: el)
            .map { "\($0)" }
    }
}

extension Database {
    func query(_ sql: String, on el: EventLoop) -> EventLoopFuture<[PostgresRow]> {
        guard let pool = pool, self.isConfigured else {
            fatalError("this database hasn't been configured yet. Please call `configure` before running any queries.")
        }
        
        print("Running query '\(sql)'")
        
        return pool.database(logger: .init(label: "wtf"))
            .simpleQuery(sql)
            // Need to resolve a promise on the event loop that created it, therefore, hop to the sending
            // event loop before returning, since grabbing a random loop from the pool will likely change
            // event loops.
            .hop(to: el)
        // Alternatively, run the DB query on the sending event loop? Need to thing more about when to do
        // what.
//        return pool.withConnection(logger: nil, on: el) { conn in
//            conn.simpleQuery(sql)
//        }
    }
}
