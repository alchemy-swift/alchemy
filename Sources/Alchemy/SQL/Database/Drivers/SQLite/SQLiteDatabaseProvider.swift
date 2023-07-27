import SQLiteKit

final class SQLiteDatabaseProvider: DatabaseProvider {
    /// The connection pool from which to make connections to the
    /// database with.
    let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>

    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: the info needed to connect to the
    ///   database.
    init(config: SQLiteConfiguration) {
        let source = SQLiteConnectionSource(configuration: config, threadPool: Thread.pool)
        pool = EventLoopGroupConnectionPool(source: source, on: Loop.group)
    }
    
    // MARK: Database
    
    func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        try await withConnection { try await $0.query(sql, parameters: parameters) }
    }
    
    func raw(_ sql: String) async throws -> [SQLRow] {
        try await withConnection { try await $0.raw(sql) }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await withConnection { conn in
            _ = try await conn.raw("BEGIN;")
            let val = try await action(conn)
            _ = try await conn.raw("COMMIT;")
            return val
        }
    }
    
    func shutdown() throws {
        try pool.syncShutdownGracefully()
    }
    
    private func withConnection<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) {
            try await action(SQLiteConnectionDatabase(conn: $0))
        }
    }
}

private struct SQLiteConnectionDatabase: DatabaseProvider {
    let conn: SQLiteConnection

    func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        let parameters = parameters.map(SQLiteData.init)
        return try await conn.query(sql, parameters)
            .get()
            .map(SQLRow.init)
    }
    
    func raw(_ sql: String) async throws -> [SQLRow] {
        try await conn.query(sql)
            .get()
            .map(SQLRow.init)
    }
    
    func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}

extension SQLRow {
    init(sqlite: SQLiteRow) throws {
        self.init(fields: sqlite.columns.map { ($0.name, $0.data) })
    }
}
