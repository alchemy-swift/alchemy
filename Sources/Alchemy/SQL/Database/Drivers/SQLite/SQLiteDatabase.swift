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
    
    func query(_ sql: String, values: [SQLValue]) async throws -> [SQLRow] {
        try await withConnection { try await $0.query(sql, values: values) }
    }
    
    func raw(_ sql: String) async throws -> [SQLRow] {
        try await withConnection { try await $0.raw(sql) }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await withConnection { conn in
            _ = try await conn.query("BEGIN;", values: [])
            let val = try await action(conn)
            _ = try await conn.query("COMMIT;", values: [])
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
    
    func query(_ sql: String, values: [SQLValue]) async throws -> [SQLRow] {
        try await conn.query(sql, values.map(SQLiteData.init)).get().map(SQLiteDatabaseRow.init)
    }
    
    func raw(_ sql: String) async throws -> [SQLRow] {
        try await conn.query(sql).get().map(SQLiteDatabaseRow.init)
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}
