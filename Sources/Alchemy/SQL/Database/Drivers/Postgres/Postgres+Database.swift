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

    // MARK: Database
    
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
            on: Container.global.resolve(EventLoopGroup.self)
        )
    }
    
    func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        withConnection { $0.runRawQuery(sql, values: values) }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        withConnection { conn in
            conn.runRawQuery("START TRANSACTION;", values: [])
                .flatMap { _ in action(conn) }
                .flatMap { conn.runRawQuery("COMMIT;", values: []).transform(to: $0) }
        }
    }
    
    func shutdown() throws {
        try pool.syncShutdownGracefully()
    }
    
    private func withConnection<T>(_ action: @escaping (DatabaseDriver) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return pool.withConnection(logger: Log.logger, on: Loop.current) {
            action(PostgresConnectionDatabase(conn: $0, grammar: self.grammar))
        }
    }
}

public extension Database {
    static func postgres(host: String,
        port: Int = 5432,
        database: String,
        username: String,
        password: String
    ) -> Database {
        return postgres(config: DatabaseConfig(
            socket: .ip(host: host, port: port),
            database: database,
            username: username,
            password: password
        ))
    }
    
    static func postgres(config: DatabaseConfig) -> Database {
        Database(driver: PostgresDatabase(config: config))
    }
}

/// A database to send through on transactions.
private struct PostgresConnectionDatabase: DatabaseDriver {
    let conn: PostgresConnection
    let grammar: Grammar
    
    func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        conn.query(sql.positionPostgresBindings(), values.map(PostgresData.init))
            .map { $0.rows.map(PostgresDatabaseRow.init) }
    }
    
    func transaction<T>(_ action: @escaping (DatabaseDriver) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        action(self)
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
}
