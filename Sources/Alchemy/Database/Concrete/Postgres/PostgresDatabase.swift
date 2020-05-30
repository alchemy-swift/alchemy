import Foundation
import PostgresKit
import NIO

public final class PostgresDatabase: Database {
    private typealias ConnectionPool = EventLoopGroupConnectionPool<PostgresConnectionSource>
    
    private let config: PostgresConfig
    private let pool: ConnectionPool

    public let grammar = Grammar()
    
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
    
    public func runRawQuery(_ sql: String, on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        self.pool
            .withConnection(logger: nil, on: loop) { $0.simpleQuery(sql) }
            // Required for type inference.
            .map { $0 }
    }
    
    public func runQuery(_ sql: String, values: [DatabaseValue], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        print(sql)
        print(values)
        return self.pool.withConnection(logger: nil, on: loop) { conn in
            conn.query(
                self.positionBindings(sql),
                values.map { $0.toPostgresData() }
            ).map { $0.rows }
        }
    }
    
    public func shutdown() {
        self.pool.shutdown()
    }

    private func positionBindings(_ sql: String) -> String {

        //TODO: Ensure a user can enter ? into their content?
        return sql.replaceAll(matching: "(\\?)") { (index, _) in
            return "$\(index + 1)"
        }
    }
}
