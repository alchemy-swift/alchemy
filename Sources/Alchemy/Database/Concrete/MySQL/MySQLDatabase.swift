import MySQLKit
import NIO

public final class MySQLDatabase: Database {
    private typealias ConnectionPool = EventLoopGroupConnectionPool<MySQLConnectionSource>

    private let config: MySQLConfig
    private let pool: ConnectionPool

    public let grammar = Grammar()

    public init(config: MySQLConfig, eventLoopGroup: EventLoopGroup) {
        //  Initialize the pool.
        let mysqlConfig: MySQLConfiguration
        switch config.socket {
        case .ipAddress(let host, let port):
            mysqlConfig = .init(
                hostname: host,
                port: port,
                username: config.username,
                password: config.password,
                database: config.database,
                tlsConfiguration: nil
            )
        case .unixSocket(let name):
            mysqlConfig = .init(
                unixDomainSocketPath: name,
                username: config.username,
                password: config.password,
                database: config.database
            )
        }

        let pool = EventLoopGroupConnectionPool(
            source: MySQLConnectionSource(configuration: mysqlConfig),
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

    public func query(_ sql: String, values: [DatabaseValue], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        print(sql)
        print(values)
        return self.pool.withConnection(logger: nil, on: loop) { conn in
            conn.query(sql, values.map { $0.toMySQLData() })
                .map { $0 }
        }
    }

    public func shutdown() {
        self.pool.shutdown()
    }
}
