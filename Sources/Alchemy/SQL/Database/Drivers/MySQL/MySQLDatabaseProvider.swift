import MySQLKit
import NIO

public final class MySQLDatabaseProvider: DatabaseProvider {
    /// The connection pool from which to make connections to the
    /// database with.
    public let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>

    public init(config: MySQLConfiguration) {
        let source = MySQLConnectionSource(configuration: config)
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
            try await $0.mysqlTransaction(action)
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

extension MySQLConnection: DatabaseProvider {
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
    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await mysqlTransaction(action)
    }

    public func shutdown() async throws {
        try await close().get()
    }
}

extension DatabaseProvider {
    fileprivate func mysqlTransaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await raw("START TRANSACTION;")
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

extension MySQLRow {
    fileprivate var _row: SQLRow {
        SQLRow(fields: columnDefinitions.map {
            guard let value = column($0.name) else {
                preconditionFailure("MySQLRow had a key but no value for column `\($0.name)`!")
            }

            return (column: $0.name, value: value)
        })
    }
}
