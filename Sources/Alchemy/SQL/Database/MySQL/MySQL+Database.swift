import MySQLKit
import NIO

public final class MySQLDatabase: Database {
    /// The connection pool from which to make connections to the
    /// database with.
    private let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    
    // MARK: Database
    
    public var grammar: Grammar = MySQLGrammar()
    public var migrations: [Migration] = []

    /// Initialize with the given configuration. The configuration
    /// will be connected to when a query is run.
    ///
    /// - Parameter config: The info needed to connect to the
    ///   database.
    public init(config: DatabaseConfig) {
        self.pool = EventLoopGroupConnectionPool(
            source: MySQLConnectionSource(configuration: {
                switch config.socket {
                case .ip(let host, let port):
                    return MySQLConfiguration(
                        hostname: host,
                        port: port,
                        username: config.username,
                        password: config.password,
                        database: config.database,
                        tlsConfiguration: nil
                    )
                case .unix(let name):
                    return MySQLConfiguration(
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
    
    public func runRawQuery(
        _ sql: String,
        values: [DatabaseValue]
    ) -> EventLoopFuture<[DatabaseRow]> {
        self.pool.withConnection(logger: Log.logger, on: Services.eventLoop) { conn in

            var lastInsertId: Int?
            return conn.query(
                sql, values.map(MySQLData.init),
                onMetadata: { metadata in
                    if let lastId = metadata.lastInsertID {
                        lastInsertId = Int(lastId)
                    }
                })
                .flatMap { (rows: [MySQLRow]) -> EventLoopFuture<[MySQLRow]> in
                    if let lastTable = self.tableMatches(query: sql),
                       let lastInsertId = lastInsertId {
                        return self.getLastInsertedRow(conn, table: lastTable, id: lastInsertId)
                    }
                    return EventLoopFuture<[MySQLRow]>.new(rows)
                }
                .map { $0 }
        }
    }

    public func shutdown() throws {
        try self.pool.syncShutdownGracefully()
    }

    private func getLastInsertedRow(_ conn: MySQLConnection, table: String, id: Int) -> EventLoopFuture<[MySQLRow]> {
        let bindings = [DatabaseValue.int(id)].map(MySQLData.init)
        return conn.query("select * from \(table) where id = ?;", bindings)
    }

    private func tableMatches(query: String) -> String? {
        let pattern = "^insert into ([^ ]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let matches = regex.matches(in: query, options: [], range: NSMakeRange(0, query.count))
        return matches.map { match in
            let range = Range(match.range(at: match.numberOfRanges - 1), in: query)
            return String(query[range!])
        }.first
    }
}
