import Fusion
import Foundation
import PostgresKit
import NIO

/// A concrete `Database` for connecting to and querying a PostgreSQL
/// database.
final class PostgresDatabase: DatabaseDriver {
    /// The connection pool from which to make connections to the
    /// database with.
    private let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>

    let grammar: Grammar = PostgresGrammar()
    
    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: the info needed to connect to the
    ///   database.
    init(config: DatabaseConfig) {
        self.pool = EventLoopGroupConnectionPool(
            source: PostgresConnectionSource(configuration: {
                switch config.socket {
                case .ip(let host, let port):
                    var tlsConfig = config.enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
                    tlsConfig?.certificateVerification = .none
                    return PostgresConfiguration(
                        hostname: host,
                        port: port,
                        username: config.username,
                        password: config.password,
                        database: config.database,
                        tlsConfiguration: tlsConfig
                    )
                case .unix(let name):
                    return PostgresConfiguration(
                        unixDomainSocketPath: name,
                        username: config.username,
                        password: config.password,
                        database: config.database
                    )
                }
            }()),
            on: Loop.group
        )
    }
    
    // MARK: Database
    
    func runRawQuery(_ sql: String, values: [SQLValue]) async throws -> [DatabaseRow] {
        try await withConnection { try await $0.runRawQuery(sql, values: values) }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await withConnection { conn in
            _ = try await conn.runRawQuery("START TRANSACTION;", values: [])
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
            try await action(PostgresConnectionDatabase(conn: $0, grammar: self.grammar))
        }
    }
}

public extension Database {
    /// Creates a PostgreSQL database configuration.
    ///
    /// - Parameters:
    ///   - host: The host the database is running on.
    ///   - port: The port the database is running on.
    ///   - database: The name of the database to connect to.
    ///   - username: The username to authorize with.
    ///   - password: The password to authorize with.
    /// - Returns: The configuration for connecting to this database.
    static func postgres(host: String, port: Int = 5432, database: String, username: String, password: String) -> Database {
        return postgres(config: DatabaseConfig(
            socket: .ip(host: host, port: port),
            database: database,
            username: username,
            password: password
        ))
    }
    
    /// Create a PostgreSQL database configuration.
    ///
    /// - Parameter config: The raw configuration to connect with.
    /// - Returns: The configured database.
    static func postgres(config: DatabaseConfig) -> Database {
        Database(driver: PostgresDatabase(config: config))
    }
}

/// A database driver that is wrapped around a single connection to
/// with which to send transactions.
private struct PostgresConnectionDatabase: DatabaseDriver {
    let conn: PostgresConnection
    let grammar: Grammar
    
    func runRawQuery(_ sql: String, values: [SQLValue]) async throws -> [DatabaseRow] {
        try await conn.query(sql.positionPostgresBindings(), values.map(PostgresData.init))
            .get().rows.map(PostgresDatabaseRow.init)
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    func shutdown() throws {
        _ = conn.close()
    }
}

private extension String {
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
    func replaceAll(matching pattern: String, callback: (Int, String) -> String?) -> String {
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
                guard let replacement = callback(size-index, token) else { return }
                current.replaceSubrange(range, with: replacement)
        }
    }
}
