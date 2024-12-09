import AsyncKit
import SQLiteNIO

public final class SQLiteDatabaseProvider: DatabaseProvider {
    public var type: DatabaseType { .sqlite }

    /// The connection pool from which to make connections to the
    /// database with.
    public let pool: EventLoopGroupConnectionPool<SQLiteConfiguration>

    public init(configuration: SQLiteConfiguration) {
        pool = EventLoopGroupConnectionPool(source: configuration, on: LoopGroup)
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

    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T)
        async throws -> T
    {
        try await withConnection {
            try await $0.sqliteTransaction(action)
        }
    }

    public func shutdown() async throws {
        try await pool.asyncShutdownGracefully()
    }

    private func withConnection<T>(_ action: @escaping (DatabaseProvider) async throws -> T)
        async throws -> T
    {
        try await pool.withConnection(logger: Log, on: Loop) {
            try await action($0)
        }
    }
}

extension SQLiteConnection: DatabaseProvider, @retroactive ConnectionPoolItem {
    public var type: DatabaseType { .sqlite }

    public func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        let parameters = parameters.map(SQLiteData.init)
        return try await query(sql, parameters).get().map(\._row)
    }

    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await query(sql).get().map(\._row)
    }

    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T)
        async throws -> T
    {
        try await sqliteTransaction(action)
    }

    public func shutdown() async throws {
        try await close().get()
    }
}

extension DatabaseProvider {
    fileprivate func sqliteTransaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T)
        async throws -> T
    {
        try await raw("BEGIN;")
        do {
            let val = try await action(self)
            try await raw("COMMIT;")
            return val
        } catch {
            Log.debug("Transaction failed. Rolling back.")
            try await raw("ROLLBACK;")
            throw error
        }
    }
}

extension SQLiteRow {
    fileprivate var _row: SQLRow {
        SQLRow(fields: columns.map { ($0.name, $0.data) })
    }
}
