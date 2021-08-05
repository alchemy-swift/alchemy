import MySQLKit
import NIO

public final class MySQLDatabase: Database {
    /// The connection pool from which to make connections to the
    /// database with.
    private let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    
    // MARK: Database
    
    public var grammar: Grammar = MySQLGrammar()
    public var migrations: [Migration] = []

    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: The info needed to connect to the
    ///   database.
    public init(config: DatabaseConfig) {
        self.pool = EventLoopGroupConnectionPool(
            source: MySQLConnectionSource(configuration: {
                switch config.socket {
                case .ip(let host, let port):
                    var tlsConfig = config.enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
                    tlsConfig?.certificateVerification = .none
                    return MySQLConfiguration(
                        hostname: host,
                        port: port,
                        username: config.username,
                        password: config.password,
                        database: config.database,
                        tlsConfiguration: tlsConfig
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
        withConnection { $0.runRawQuery(sql, values: values) }
    }
    
    /// MySQL doesn't have a way to return a row after inserting. This
    /// runs a query and if MySQL metadata contains a `lastInsertID`,
    /// fetches the row with that id from the given table.
    ///
    /// - Parameters:
    ///   - sql: The SQL to run.
    ///   - table: The table from which `lastInsertID` should be
    ///     fetched.
    ///   - values: Any bindings for the query.
    /// - Returns: A future containing the result of fetching the last
    ///   inserted id, or the result of the original query.
    func runAndReturnLastInsertedItem(_ sql: String, table: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        pool.withConnection(logger: Log.logger, on: Services.eventLoop) { conn in
            var lastInsertId: Int?
            return conn
                .query(sql, values.map(MySQLData.init), onMetadata: { lastInsertId = $0.lastInsertID.map(Int.init) })
                .flatMap { rows -> EventLoopFuture<[MySQLRow]> in
                    if let lastInsertId = lastInsertId {
                        return conn.query("select * from \(table) where id = ?;", [MySQLData(.int(lastInsertId))])
                    } else {
                        return .new(rows)
                    }
                }
                .map { $0.map(MySQLDatabaseRow.init) }
        }
    }
    
    public func transaction<T>(_ action: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        withConnection { database in
            let conn = database.conn
            // SimpleQuery since MySQL can't handle START TRANSACTION in prepared statements.
            return conn.simpleQuery("START TRANSACTION;")
                .flatMap { _ in action(database) }
                .flatMap { conn.simpleQuery("COMMIT;").transform(to: $0) }
        }
    }

    private func withConnection<T>(_ action: @escaping (MySQLConnectionDatabase) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return pool.withConnection(logger: Log.logger, on: Services.eventLoop) {
            action(MySQLConnectionDatabase(conn: $0, grammar: self.grammar, migrations: self.migrations))
        }
    }
    
    public func shutdown() throws {
        try self.pool.syncShutdownGracefully()
    }
}

/// A database to send through on transactions.
private struct MySQLConnectionDatabase: Database {
    let conn: MySQLConnection
    let grammar: Grammar
    var migrations: [Migration]
    
    func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        return conn.query(sql, values.map(MySQLData.init))
            .map { $0.map(MySQLDatabaseRow.init) }
    }
    
    func transaction<T>(_ action: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}
