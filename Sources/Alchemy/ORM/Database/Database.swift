import PostgresKit

public class Database<Kind> {
    let config: DatabaseConfig
    let pool: ConnectionPool
    
    public init(config: DatabaseConfig, eventLoopGroup: EventLoopGroup) {
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
        
        self.config = config
        self.pool = pool
    }
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
    public func shutdown() {
        self.pool.shutdown()
    }
    
    public func test(on loop: EventLoop) -> EventLoopFuture<String> {
        return self.query("SELECT version()", on: loop)
            .map { "\($0)" }
    }
}

extension Database {
    func query(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[PostgresRow]> {
        print("Running query '\(sql)'")
        return pool.withConnection(logger: nil, on: loop) { conn in
            conn.simpleQuery(sql)
        }
    }
}
