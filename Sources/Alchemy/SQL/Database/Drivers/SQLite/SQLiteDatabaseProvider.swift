import SQLiteKit

public final class SQLiteDatabaseProvider: DatabaseProvider {
    /// The connection pool from which to make connections to the
    /// database with.
    public let pool: EventLoopGroupConnectionPool<SQLiteConnectionSource>

    public init(config: SQLiteConfiguration) {
        let source = SQLiteConnectionSource(configuration: config, threadPool: Thread.pool)
        pool = EventLoopGroupConnectionPool(source: source, on: Loop.group)
    }
    
    // MARK: Database
    
    public func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        try await withConnection {
            try await $0.query(sql, parameters: parameters)
        }
    }
    
    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await withConnection {
            try await $0.raw(sql)
        }
    }
    
    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await withConnection {
            try await $0.sqliteTransaction(action)
        }
    }
    
    public func shutdown() async throws {
        try await pool.asyncShutdownGracefully()
    }
    
    private func withConnection<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) {
            try await action($0)
        }
    }
}

extension SQLiteConnection: DatabaseProvider {
    public func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        let parameters = parameters.map(SQLiteData.init)
        return try await query(sql, parameters).get().map(\._row)
    }

    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await query(sql).get().map(\._row)
    }

    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await sqliteTransaction(action)
    }

    public func shutdown() async throws {
        try await close().get()
    }
}

extension DatabaseProvider {
    fileprivate func sqliteTransaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await raw("BEGIN;")
        do {
            let val = try await action(self)
            try await raw("COMMIT;")
            return val
        } catch {
            Log.error("[Database] transaction failed with error \(error). Rolling back.")
            try await raw("ROLLBACK;")
            try await raw("COMMIT;")
            throw error
        }
    }
}

extension SQLiteRow {
    fileprivate var _row: SQLRow {
        SQLRow(fields: columns.map { ($0.name, $0.data) })
    }
}
