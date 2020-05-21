import PostgresKit
import NIO

public final class PostgresDatabase: Database {
    private typealias ConnectionPool = EventLoopGroupConnectionPool<PostgresConnectionSource>
    
    private let config: PostgresConfig
    private let pool: ConnectionPool
    
    public init(config: PostgresConfig, eventLoopGroup: EventLoopGroup) {
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
    
    public func rawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        self.pool
            .withConnection(logger: nil, on: loop) { $0.simpleQuery(sql) }
            // Required for type inference.
            .map { $0 }
    }
    
    public func query(_ sql: String, values: [DatabaseField.Value], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        self.pool.withConnection(logger: nil, on: loop) { conn in
            conn.query(sql, values.map { $0.toPostgresData() })
                .map { $0.rows }
        }
    }
    
    public func shutdown() {
        self.pool.shutdown()
    }
}
