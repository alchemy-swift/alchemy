import MySQLKit
import NIO

public final class MySQLDatabase: Database {
    private typealias ConnectionPool = EventLoopGroupConnectionPool<MySQLConnectionSource>

    private let config: MySQLConfig
    private let pool: ConnectionPool

    public let grammar: Grammar = MySQLGrammar()

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
            conn.query(sql, values.map { $0.toMySQLData() })
                .map { $0 }
        }
    }

    public func shutdown() {
        self.pool.shutdown()
    }
}

private class MySQLGrammar: Grammar {
    override func compileInsert(_ query: Query, values: [OrderedDictionary<String, Parameter>]) throws -> SQL {
        var initial = try super.compileInsert(query, values: values)
        initial.query.append("; select * from table where Id=LAST_INSERT_ID();")
        return initial
    }
}
