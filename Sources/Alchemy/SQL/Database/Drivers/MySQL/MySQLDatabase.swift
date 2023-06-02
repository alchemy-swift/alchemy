import MySQLKit
import NIO

final class MySQLDatabase: DatabaseProvider {
    /// The connection pool from which to make connections to the
    /// database with.
    let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    
    var grammar: Grammar = MySQLGrammar()
    let dialect: SQLDialect = MySQLDialect()

    init(socket: Socket, database: String, username: String, password: String, tlsConfiguration: TLSConfiguration? = nil) {
        pool = EventLoopGroupConnectionPool(
            source: MySQLConnectionSource(configuration: {
                switch socket {
                case .ip(let host, let port):
                    return MySQLConfiguration(
                        hostname: host,
                        port: port,
                        username: username,
                        password: password,
                        database: database,
                        tlsConfiguration: tlsConfiguration
                    )
                case .unix(let name):
                    return MySQLConfiguration(
                        unixDomainSocketPath: name,
                        username: username,
                        password: password,
                        database: database
                    )
                }
            }()),
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
            try await action(MySQLConnectionDatabase(conn: $0, grammar: self.grammar, dialect: self.dialect))
        }
    }
    
    func shutdown() throws {
        try self.pool.syncShutdownGracefully()
    }
}

/// A database to send through on transactions.
private struct MySQLConnectionDatabase: DatabaseProvider {
    let conn: MySQLConnection
    let grammar: Grammar
    let dialect: SQLDialect
    
    func query(_ sql: String, values: [SQLValue]) async throws -> [SQLRow] {
        try await conn.query(sql, values.map(MySQLData.init)).get().map(SQLRow.init)
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
