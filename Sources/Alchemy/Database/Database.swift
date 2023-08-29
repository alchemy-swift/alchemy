import Foundation
import NIOConcurrencyHelpers

/// Used for interacting with an SQL database. This class is an
/// injectable `Service` so you can register the default one
/// via `Database.config(default: .postgres())`.
public final class Database: Service {
    public typealias Identifier = ServiceIdentifier<Database>

    /// Any migrations associated with this database, whether run yet or not.
    public var migrations: [Migration] = []
    
    /// Any seeders associated with this database.
    public var seeders: [Seeder] = []

    /// The mapping from Swift types to tables and columns in this database.
    public var keyMapping: KeyMapping = .snakeCase

    /// Functions around compiling SQL statments for this database's
    /// SQL dialect when using the QueryBuilder or Rune.
    public var grammar: SQLGrammar

    /// The provider of this database.
    public var provider: DatabaseProvider {
        get {
            lock.withLock {
                if let _provider {
                    return _provider
                } else {
                    let provider = createProvider()
                    _provider = provider
                    return provider
                }
            }
        }
    }

    private let lock = NIOLock()
    private var _provider: DatabaseProvider? = nil
    private let createProvider: () -> DatabaseProvider

    /// Whether this database should log all queries at the `debug` level.
    var logging: QueryLogging? = nil

    /// Create a database backed by the given provider.
    ///
    /// - Parameter provider: The provider.
    public convenience init(provider: @escaping @autoclosure () -> DatabaseProvider, grammar: SQLGrammar) {
        self.init(provider: provider(), grammar: grammar, logging: nil)
    }

    init(provider: @escaping @autoclosure () -> DatabaseProvider, grammar: SQLGrammar, logging: QueryLogging? = nil) {
        self.createProvider = provider
        self.grammar = grammar
        self.logging = logging
    }

    /// Log all executed queries to the `debug` level.
    public func log() -> Self {
        self.logging = .log
        return self
    }

    public func logRawSQL() -> Self {
        self.logging = .logRawSQL
        return self
    }

    /// Set custom key mapping for this database.
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
        try await provider.query(sql, parameters: parameters)
    }

    /// Run a raw, not parametrized SQL string.
    ///
    /// - Returns: The rows returned by the query.
    @discardableResult
    public func raw(_ sql: String) async throws -> [SQLRow] {
        try await provider.raw(sql)
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
}
