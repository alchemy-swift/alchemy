import Fusion
import Foundation
import PostgresKit
import NIO

public final class PostgresDatabase: Database {
    private typealias ConnectionPool = EventLoopGroupConnectionPool<PostgresConnectionSource>
    
    private let config: PostgresConfig
    private let pool: ConnectionPool

    public let grammar: Grammar = PostgresGrammar()
    
    public init(
        config: PostgresConfig,
        eventLoopGroup: EventLoopGroup = try! Container.global.resolve(MultiThreadedEventLoopGroup.self)
    ) {
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
            .withConnection(logger: nil, on: loop) { $0.query(sql) }
            // Required for type inference.
            .map { $0.rows }
    }
    
    public func runQuery(_ sql: String, values: [DatabaseValue], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]>
    {
        self.pool.withConnection(logger: nil, on: loop) { conn in
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
        // TODO: Ensure a user can enter ? into their content?
        sql.replaceAll(matching: "(\\?)") { (index, _) in
            return "$\(index + 1)"
        }
    }
}

private class PostgresGrammar: Grammar {
    override func compileInsert(_ query: Query, values: [OrderedDictionary<String, Parameter>]) throws -> SQL {
        var initial = try super.compileInsert(query, values: values)
        initial.query.append(" returning *")
        return initial
    }
}
