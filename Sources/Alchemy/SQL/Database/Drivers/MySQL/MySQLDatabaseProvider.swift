import MySQLKit
import NIO

final class MySQLDatabaseProvider: DatabaseProvider {
    /// The connection pool from which to make connections to the
    /// database with.
    let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>

    init(config: MySQLConfiguration) {
        let source = MySQLConnectionSource(configuration: config)
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
        try await withConnection {
            _ = try await $0.raw("START TRANSACTION;")
            let val = try await action($0)
            _ = try await $0.raw("COMMIT;")
            return val
        }
    }

    private func withConnection<T>(_ action: @escaping (MySQLConnectionDatabase) async throws -> T) async throws -> T {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) {
            try await action(MySQLConnectionDatabase(conn: $0))
        }
    }
    
    func shutdown() throws {
        try self.pool.syncShutdownGracefully()
    }
}

/// A database to send through on transactions.
private struct MySQLConnectionDatabase: DatabaseProvider {
    let conn: MySQLConnection

    func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        try await conn.query(sql, parameters.map(MySQLData.init)).get().map(SQLRow.init)
    }
    
    func raw(_ sql: String) async throws -> [SQLRow] {
        try await conn.simpleQuery(sql).get().map(SQLRow.init)
    }
    
    func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}

extension SQLRow {
    init(mysql: MySQLRow) throws {
        let fields = mysql.columnDefinitions.map {
            guard let value = mysql.column($0.name) else {
                preconditionFailure("MySQLRow had a key but no value for column `\($0.name)`!")
            }

            return (column: $0.name, value: value)
        }

        self.init(fields: fields)
    }
}
