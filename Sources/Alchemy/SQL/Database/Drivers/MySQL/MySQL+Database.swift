import MySQLKit
import NIO

final class MySQLDatabase: DatabaseDriver {
    /// The connection pool from which to make connections to the
    /// database with.
    private let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    
    var grammar: Grammar = MySQLGrammar()

    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: The info needed to connect to the
    ///   database.
    init(config: DatabaseConfig) {
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
            on: Loop.group
        )
    }
    
    // MARK: Database
    
    func runRawQuery(_ sql: String, values: [SQLValue]) async throws -> [DatabaseRow] {
        try await withConnection { try await $0.runRawQuery(sql, values: values) }
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
    /// - Returns: The result of fetching the last inserted id, or the
    ///   result of the original query.
    func runAndReturnLastInsertedItem(_ sql: String, table: String, values: [SQLValue]) async throws -> [DatabaseRow] {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) { conn in
            var lastInsertId: Int?
            var rows = try await conn
                .query(sql, values.map(MySQLData.init), onMetadata: { lastInsertId = $0.lastInsertID.map(Int.init) })
                .get()
            
            if let lastInsertId = lastInsertId {
                rows = try await conn.query("select * from \(table) where id = ?;", [MySQLData(.int(lastInsertId))]).get()
            }
            
            return rows.map(MySQLDatabaseRow.init)
        }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await withConnection { database in
            let conn = database.conn
            // `simpleQuery` since MySQL can't handle START TRANSACTION in prepared statements.
            _ = try await conn.simpleQuery("START TRANSACTION;").get()
            let val = try await action(database)
            _ = try await conn.simpleQuery("COMMIT;").get()
            return val
        }
    }

    private func withConnection<T>(_ action: @escaping (MySQLConnectionDatabase) async throws -> T) async throws -> T {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) {
            try await action(MySQLConnectionDatabase(conn: $0, grammar: self.grammar))
        }
    }
    
    func shutdown() throws {
        try self.pool.syncShutdownGracefully()
    }
}

public extension Database {
    /// Creates a MySQL database configuration.
    ///
    /// - Parameters:
    ///   - host: The host the database is running on.
    ///   - port: The port the database is running on.
    ///   - database: The name of the database to connect to.
    ///   - username: The username to authorize with.
    ///   - password: The password to authorize with.
    /// - Returns: The configuration for connecting to this database.
    static func mysql(host: String, port: Int = 3306, database: String, username: String, password: String) -> Database {
        return mysql(config: DatabaseConfig(
            socket: .ip(host: host, port: port),
            database: database,
            username: username,
            password: password
        ))
    }
    
    /// Create a MySQL database configuration.
    ///
    /// - Parameter config: The raw configuration to connect with.
    /// - Returns: The configured database.
    static func mysql(config: DatabaseConfig) -> Database {
        Database(driver: MySQLDatabase(config: config))
    }
}


/// A database to send through on transactions.
private struct MySQLConnectionDatabase: DatabaseDriver {
    let conn: MySQLConnection
    let grammar: Grammar
    
    func runRawQuery(_ sql: String, values: [SQLValue]) async throws -> [DatabaseRow] {
        try await conn.query(sql, values.map(MySQLData.init)).get().map(MySQLDatabaseRow.init)
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}
