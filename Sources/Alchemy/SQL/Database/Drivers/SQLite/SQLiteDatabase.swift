import OrderedCollections
import SQLiteKit

final class SQLiteDatabase: DatabaseDriver {
    /// The connection pool from which to make connections to the
    /// database with.
    let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>
    let config: Config
    let grammar: Grammar = SQLiteGrammar()
    
    enum Config: Equatable {
        case memory
        case file(String)
    }
    
    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: the info needed to connect to the
    ///   database.
    init(config: Config) {
        self.config = config
        self.pool = EventLoopGroupConnectionPool(
            source: SQLiteConnectionSource(configuration: {
                switch config {
                case .memory:
                    return SQLiteConfiguration(storage: .memory, enableForeignKeys: true)
                case .file(let path):
                    return SQLiteConfiguration(storage: .file(path: path), enableForeignKeys: true)
                }
            }(), threadPool: .default),
            on: Loop.group
        )
    }
    
    // MARK: Database
    
    func runRawQuery(_ sql: String, values: [SQLValue]) async throws -> [SQLRow] {
        try await withConnection { try await $0.runRawQuery(sql, values: values) }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await withConnection { conn in
            _ = try await conn.runRawQuery("BEGIN;", values: [])
            let val = try await action(conn)
            _ = try await conn.runRawQuery("COMMIT;", values: [])
            return val
        }
    }
    
    func shutdown() throws {
        try pool.syncShutdownGracefully()
    }
    
    private func withConnection<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) {
            try await action(SQLiteConnectionDatabase(conn: $0, grammar: self.grammar))
        }
    }
}

private struct SQLiteConnectionDatabase: DatabaseDriver {
    let conn: SQLiteConnection
    let grammar: Grammar
    
    func runRawQuery(_ sql: String, values: [SQLValue]) async throws -> [SQLRow] {
        try await conn.query(sql, values.map(SQLiteData.init)).get().map(SQLiteDatabaseRow.init)
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}
