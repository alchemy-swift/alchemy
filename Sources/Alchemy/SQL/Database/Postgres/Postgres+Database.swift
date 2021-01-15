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
                    return PostgresConfiguration(
                        hostname: host,
                        port: port,
                        username: config.username,
                        password: config.password,
                        database: config.database
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
        self.pool.withConnection(logger: Log.logger, on: Services.eventLoop) { conn in
            conn.query(self.positionBindings(sql), values.map(PostgresData.init) )
                .map { $0.rows }
        }
    }
    
    public func shutdown() throws {
        try self.pool.syncShutdownGracefully()
    }

    /// The Alchemy query builder constructs bindings with question
    /// marks ('?') in the SQL string. PostgreSQL requires bindings
    /// to be denoted by $1, $2, etc. This function converts all
    /// '?'s to strings appropriate for Postgres bindings.
    ///
    /// - Parameter sql: The SQL string to replace bindings with.
    /// - Returns: An SQL string appropriate for running in Postgres.
    private func positionBindings(_ sql: String) -> String {
        // TODO: Ensure a user can enter ? into their content?
        sql.replaceAll(matching: "(\\?)") { (index, _) in
            "$\(index + 1)"
        }
    }
}
