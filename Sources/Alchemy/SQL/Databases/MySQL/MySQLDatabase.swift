import MySQLKit
import NIO

public final class MySQLDatabase: Database {
    private typealias ConnectionPool = EventLoopGroupConnectionPool<MySQLConnectionSource>

    private let pool: ConnectionPool
    
    public var grammar: Grammar = MySQLGrammar()
    public var migrations: [Migration] = []

    public init(config: DatabaseConfig, eventLoopGroup: EventLoopGroup) {
        //  Initialize the pool.
        let mysqlConfig: MySQLConfiguration
        switch config.socket {
        case .ip(let host, let port):
            mysqlConfig = .init(
                hostname: host,
                port: port,
                username: config.username,
                password: config.password,
                database: config.database,
                tlsConfiguration: nil
            )
        case .unix(let name):
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

        self.pool = pool
    }
    
    public func runRawQuery(_ sql: String, values: [DatabaseValue], on loop: EventLoop) -> EventLoopFuture<[DatabaseRow]> {
        self.pool.withConnection(logger: nil, on: loop) { conn in
            conn.query(sql, values.map { $0.toMySQLData() })
                .map { $0 }
        }
    }
    
    public func shutdown() {
        try! self.pool.syncShutdownGracefully()
    }
}

private class MySQLGrammar: Grammar {
    override func compileInsert(_ query: Query, values: [OrderedDictionary<String, Parameter>]) throws -> SQL {
        var initial = try super.compileInsert(query, values: values)
        initial.query.append("; select * from table where Id=LAST_INSERT_ID();")
        return initial
    }
}
