/// Used for interacting with an SQL database.
public final class Database: Service {
    public typealias Identifier = ServiceIdentifier<Database>

    /// The provider of this database.
    public let provider: DatabaseProvider

    /// The underlying DBMS type (i.e. PostgreSQL, SQLite, etc...)
    public var type: DatabaseType { provider.type }

    /// Functions around compiling SQL statments for this database's
    /// SQL dialect when using the QueryBuilder or Rune.
    public var grammar: SQLGrammar

    /// Any migrations associated with this database, whether run yet or not.
    public var migrations: [Migration] = []
    
    /// Any seeders associated with this database.
    public var seeders: [Seeder] = []

    /// The mapping from Swift types to tables and columns in this database.
    public var keyMapping: KeyMapping = .snakeCase

    /// Whether this database should log all queries at the `debug` level.
    private var logging: QueryLogging? = nil

    /// Create a database backed by the given provider.
    ///
    /// - Parameter provider: The provider.
    public convenience init(provider: DatabaseProvider, grammar: SQLGrammar) {
        self.init(provider: provider, grammar: grammar, logging: nil)
    }

    init(provider: DatabaseProvider, grammar: SQLGrammar, logging: QueryLogging? = nil) {
        self.provider = provider
        self.grammar = grammar
        self.logging = logging
    }

    /// Log all executed queries to the `debug` level.
    @discardableResult
    public func log() -> Self {
        self.logging = .log
        return self
    }

    @discardableResult
    public func logRawSQL() -> Self {
        self.logging = .logRawSQL
        return self
    }

    /// Set custom key mapping for this database.
    @discardableResult
    public func keyMapping(_ mapping: KeyMapping) -> Self {
        self.keyMapping = mapping
        return self
    }

    /// Run a parameterized query on the database. Parameterization
    /// helps protect against SQL injection.
    ///
    /// Usage:
    /// ```swift
    /// // No binds
    /// let rows = try await db.rawQuery("SELECT * FROM users where id = 1")
    /// print("Got \(rows.count) users.")
    ///
    /// // Binds, to protect against SQL injection.
    /// let rows = db.rawQuery("SELECT * FROM users where id = ?", values = [.int(1)])
    /// print("Got \(rows.count) users.")
    /// ```
    ///
    /// - Parameters:
    ///   - sql: The SQL string with '?'s denoting variables that
    ///     should be parameterized.
    ///   - parameters: An array, `[SQLValue]`, that will replace the
    ///     '?'s in `sql`. Ensure there are the same amount of values
    ///     as there are '?'s in `sql`.
    /// - Returns: The database rows returned by the query.
    @discardableResult
    public func query(_ sql: String, parameters: [SQLValue] = []) async throws -> [SQLRow] {
        try await _query(sql, parameters: parameters, logging: nil)
    }

    func _query(_ sql: String, parameters: [SQLValue] = [], logging: QueryLogging?) async throws -> [SQLRow] {
        log(SQL(sql, parameters: parameters), loggingOverride: logging)
        return try await provider.query(sql, parameters: parameters)
    }

    /// Run a raw, not parametrized SQL string.
    ///
    /// - Returns: The rows returned by the query.
    @discardableResult
    public func raw(_ sql: String) async throws -> [SQLRow] {
        log(SQL(sql, parameters: []))
        return try await provider.raw(sql)
    }
    
    /// Runs a transaction on the database, using the given closure.
    /// All database queries in the closure are executed atomically.
    ///
    /// Uses START TRANSACTION; and COMMIT; or similar under the hood.
    ///
    /// - Parameter action: The action to run atomically.
    /// - Returns: The return value of the transaction.
    @discardableResult
    public func transaction<T>(_ action: @escaping (Database) async throws -> T) async throws -> T {
        try await provider.transaction {
            try await action(Database(provider: $0, grammar: self.grammar, logging: self.logging))
        }
    }
    
    /// Shut down the database.
    ///
    /// - Throws: Any error that occurred when shutting down.
    public func shutdown() async throws {
        try await provider.shutdown()
    }

    private func log(_ sql: SQL, loggingOverride: QueryLogging? = nil) {
        if let logging = logging ?? self.logging {
            switch logging {
            case .log:
                Log.info(sql.description)
            case .logRawSQL:
                Log.info(sql.rawSQLString + ";")
            case .logFatal:
                Log.info(sql.description)
                fatalError("logf")
            case .logFatalRawSQL:
                Log.info(sql.rawSQLString + ";")
                fatalError("logf")
            }
        }
    }
}

public struct DatabaseType: Equatable {
    public let name: String

    public static let sqlite = DatabaseType(name: "SQLite")
    public static let postgres = DatabaseType(name: "PostgreSQL")
    public static let mysql = DatabaseType(name: "MySQL")
}
