import AsyncKit
import PostgresNIO

/// A concrete `Database` for connecting to and querying a PostgreSQL
/// database.
public final class PostgresDatabaseProvider: DatabaseProvider {
    /// The connection pool from which to make connections to the
    /// database with.
    public let pool: EventLoopGroupConnectionPool<PostgresConfiguration>

    public init(configuration: PostgresConfiguration) {
        pool = EventLoopGroupConnectionPool(source: configuration, on: Loop.group)
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
            try await $0.postgresTransaction(action)
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

extension PostgresConnection: DatabaseProvider, ConnectionPoolItem {
    @discardableResult
    public func query(_ sql: String, parameters: [SQLValue]) async throws -> [SQLRow] {
        let statement = sql.positionPostgresBinds()
        var binds = PostgresBindings(capacity: parameters.count)
        for parameter in parameters {
            binds.append(parameter)
        }

        let _query = PostgresQuery(unsafeSQL: statement, binds: binds)
        return try await query(_query, logger: Log.logger).collect().map(\._row)
    }

    @discardableResult
    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await query(sql, parameters: [])
    }

    @discardableResult
    public func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
        try await action(self)
    }
    
    public func shutdown() async throws {
        try await close().get()
    }
}

extension DatabaseProvider {
    fileprivate func postgresTransaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T {
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

extension PostgresRow {
    fileprivate var _row: SQLRow {
        SQLRow(fields: map { ($0.columnName, $0) })
    }
}

extension String {
    /// The Alchemy query builder constructs binds with question
    /// marks ('?') in the SQL string. PostgreSQL requires binds
    /// to be denoted by $1, $2, etc. This function converts all
    /// '?'s to strings appropriate for Postgres binds.
    ///
    /// - Parameter sql: The SQL string to replace binds with.
    /// - Returns: An SQL string appropriate for running in Postgres.
    func positionPostgresBinds() -> String {
        // TODO: Move this to Grammar
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
