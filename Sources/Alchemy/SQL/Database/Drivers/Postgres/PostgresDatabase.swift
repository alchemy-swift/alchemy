import Fusion
import Foundation
import PostgresKit
import NIO
import MySQLKit

/// A concrete `Database` for connecting to and querying a PostgreSQL
/// database.
final class PostgresDatabase: DatabaseProvider {
    /// The connection pool from which to make connections to the
    /// database with.
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>

    let grammar: Grammar = PostgresGrammar()
    let dialect: SQLDialect = PostgresDialect()
    
    init(socket: Socket, database: String, username: String, password: String, tlsConfiguration: TLSConfiguration? = nil) {
        pool = EventLoopGroupConnectionPool(
            source: PostgresConnectionSource(configuration: {
                switch socket {
                case .ip(let host, let port):
                    return PostgresConfiguration(
                        hostname: host,
                        port: port,
                        username: username,
                        password: password,
                        database: database,
                        tlsConfiguration: tlsConfiguration
                    )
                case .unix(let name):
                    return PostgresConfiguration(
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
        try await withConnection { conn in
            _ = try await conn.raw("START TRANSACTION;")
            do {
                let val = try await action(conn)
                _ = try await conn.raw("COMMIT;")
                return val
            } catch {
                Log.error("[Database] postgres transaction failed with error \(error). Rolling back.")
                _ = try await conn.raw("ROLLBACK;")
                _ = try await conn.raw("COMMIT;")
                throw error
            }
        }
    }
    
    func shutdown() throws {
        try pool.syncShutdownGracefully()
    }
    
    private func withConnection<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await pool.withConnection(logger: Log.logger, on: Loop.current) {
            try await action($0)
        }
    }
}

extension SQLRow {
    init(postgres: PostgresRow) throws {
        let fields = try postgres.map { SQLField(column: $0.columnName, value: try $0.toSQLValue()) }
        self.init(fields: fields)
    }
}

extension PostgresCell {
    func toSQLValue() throws -> SQLValue {
        switch dataType {
        case .int2, .int4, .int8:
            guard let int = try decode(Int?.self, context: .default) else {
                return .null
            }

            return .int(int)
        case .bool:
            guard let bool = try decode(Bool?.self, context: .default) else {
                return .null
            }

            return .bool(bool)
        case .varchar, .text:
            guard let str = try decode(String?.self, context: .default) else {
                return .null
            }

            return .string(str)
        case .date, .timestamptz, .timestamp:
            guard let date = try decode(Date?.self, context: .default) else {
                return .null
            }

            return .date(date)
        case .float4, .float8:
            guard let double = try decode(Double?.self, context: .default) else {
                return .null
            }

            return .double(double)
        case .uuid:
            guard let uuid = try decode(UUID?.self, context: .default) else {
                return .null
            }

            return .uuid(uuid)
        case .json, .jsonb:
            guard let json = try decode(Data?.self, context: .default) else {
                return .null
            }

            return .json(json)
        case .null:
            return .null
        default:
            throw DatabaseError("Couldn't parse a `\(dataType)` from \(columnName). That PostgreSQL datatype isn't supported, yet.")
        }
    }
}

/// A database provider that is wrapped around a single connection to with which
/// to send transactions.
extension PostgresConnection: DatabaseProvider {
    public var grammar: Grammar { PostgresGrammar() }
    public var dialect: SQLDialect { PostgresDialect() }

    public func query(_ sql: String, values: [SQLValue]) async throws -> [SQLRow] {
        try await query(sql.positionPostgresBindings(), values.map(PostgresData.init))
            .get().rows.map(SQLRow.init)
    }
    
    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await simpleQuery(sql).get().map(SQLRow.init)
    }
    
    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    public func shutdown() throws {
        _ = close()
    }
}

extension String {
    /// The Alchemy query builder constructs bindings with question
    /// marks ('?') in the SQL string. PostgreSQL requires bindings
    /// to be denoted by $1, $2, etc. This function converts all
    /// '?'s to strings appropriate for Postgres bindings.
    ///
    /// - Parameter sql: The SQL string to replace bindings with.
    /// - Returns: An SQL string appropriate for running in Postgres.
    func positionPostgresBindings() -> String {
        // TODO: Ensure a user can enter ? into their content?
        replaceAll(matching: "(\\?)") { (index, _) in "$\(index + 1)" }
    }
    
    /// Replace all instances of a regex pattern with a string,
    /// determined by a closure.
    ///
    /// - Parameters:
    ///   - pattern: The pattern to replace.
    ///   - callback: The closure used to define replacements for the
    ///     pattern. Takes an index and a string that is the token to
    ///     replace.
    /// - Returns: The string with replaced patterns.
    func replaceAll(matching pattern: String, callback: (Int, String) -> String) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = expression
            .matches(in: self, options: [], range: NSRange(startIndex..<endIndex, in: self))
        let size = matches.count - 1
        return matches.reversed()
            .enumerated()
            .reduce(into: self) { (current, match) in
                let (index, result) = match
                let range = Range(result.range, in: current)!
                let token = String(current[range])
                let replacement = callback(size-index, token)
                current.replaceSubrange(range, with: replacement)
        }
    }
}
