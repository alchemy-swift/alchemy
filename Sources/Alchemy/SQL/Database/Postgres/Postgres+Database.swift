import Fusion
import Foundation
import PostgresKit
import NIO

/// A concrete `Database` for connecting to and querying a PostgreSQL
/// database.
public final class PostgresDatabase: Database {
    /// The connection pool from which to make connections to the
    /// database with.
    private let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>

    // MARK: Database
    
    public let grammar: Grammar = PostgresGrammar()
    public var migrations: [Migration] = []
    
    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: the info needed to connect to the
    ///   database.
    public init(config: DatabaseConfig) {
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
    
    public func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        withConnection { $0.runRawQuery(sql, values: values) }
    }
    
    public func transaction<T>(_ action: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        withConnection { conn in
            conn.runRawQuery("START TRANSACTION;")
                .flatMap { _ in action(conn) }
                .flatMap { conn.runRawQuery("COMMIT;").transform(to: $0) }
        }
    }
    
    public func shutdown() throws {
        try pool.syncShutdownGracefully()
    }
    
    private func withConnection<T>(_ action: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return pool.withConnection(logger: Log.logger, on: Services.eventLoop) {
            action(PostgresConnectionDatabase(conn: $0, grammar: self.grammar, migrations: self.migrations))
        }
    }
}

/// A database to send through on transactions.
private struct PostgresConnectionDatabase: Database {
    let conn: PostgresConnection
    let grammar: Grammar
    var migrations: [Migration]
    
    func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        conn.query(sql.positionPostgresBindings(), values.map(PostgresData.init))
            .map { $0.rows.map(PostgresDatabaseRow.init) }
    }
    
    func transaction<T>(_ action: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
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
