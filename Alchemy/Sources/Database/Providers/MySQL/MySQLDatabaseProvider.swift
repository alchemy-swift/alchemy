import AsyncKit
import MySQLNIO
import NIOSSL

public final class MySQLDatabaseProvider: DatabaseProvider {
    public var type: DatabaseType { .mysql }

    /// The connection pool from which to make connections to the
    /// database with.
    public let pool: EventLoopGroupConnectionPool<MySQLConfiguration>

    public init(configuration: MySQLConfiguration) {
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
            try await $0.mysqlTransaction(action)
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

extension MySQLConnection: DatabaseProvider, @retroactive ConnectionPoolItem {
    public var type: DatabaseType { .mysql }

    @discardableResult
    public func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        let binds = parameters.map(MySQLData.init)
        return try await query(sql, binds).get().map(\._row)
    }

    @discardableResult
    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await simpleQuery(sql).get().map(\._row)
    }

    @discardableResult
    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T)
        async throws -> T
    {
        try await mysqlTransaction(action)
    }

    public func shutdown() async throws {
        try await close().get()
    }
}

extension DatabaseProvider {
    fileprivate func mysqlTransaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T)
        async throws -> T
    {
        try await raw("START TRANSACTION;")
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

extension MySQLRow {
    fileprivate var _row: SQLRow {
        SQLRow(
            fields: columnDefinitions.map {
                guard let value = column($0.name) else {
                    preconditionFailure("MySQLRow had a key but no value for column `\($0.name)`!")
                }

                return (column: $0.name, value: value)
            })
    }
}
