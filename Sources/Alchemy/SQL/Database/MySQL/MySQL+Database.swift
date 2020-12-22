import MySQLKit
import NIO

public final class MySQLDatabase: Database {
    /// The connection pool from which to make connections to the database with.
    private let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    
    // MARK: Database
    
    public var grammar: Grammar = MySQLGrammar()
    public var migrations: [Migration] = []

    /// Initialize with the given configuration. The configuration will be
    /// connected to when a query is run.
    ///
    /// - Parameter config: the info needed to connect to the database.
    public init(config: DatabaseConfig) {
        self.pool = EventLoopGroupConnectionPool(
            source: MySQLConnectionSource(configuration: {
                switch config.socket {
                case .ip(let host, let port):
                    return MySQLConfiguration(
                        hostname: host,
                        port: port,
                        username: config.username,
                        password: config.password,
                        database: config.database,
                        tlsConfiguration: nil
                    )
                case .unix(let name):
                    return MySQLConfiguration(
                        unixDomainSocketPath: name,
                        username: config.username,
                        password: config.password,
                        database: config.database
                    )
                }
            }()),
            on: Container.global.resolve(EventLoopGroup.self)
        )
    }
    
    public func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        self.pool.withConnection(logger: nil, on: Loop.current) { conn in
            conn.query(sql, values.map(MySQLData.init))
                .map { $0 }
        }
    }
    
    public func shutdown() {
        try! self.pool.syncShutdownGracefully()
    }
}
