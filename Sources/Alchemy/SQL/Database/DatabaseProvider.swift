/// A generic type to represent any database you might be interacting
/// with. Currently, the only two implementations are
/// `PostgresDatabase` and `MySQLDatabase`. The QueryBuilder and Rune
/// ORM are built on top of this abstraction.
public protocol DatabaseProvider {
    /// Functions around compiling SQL statments for this database's
    /// SQL dialect when using the QueryBuilder or Rune.
    var grammar: Grammar { get }

    var dialect: SQLDialect { get }
    
    /// Run a parameterized query on the database. Parameterization
    /// helps protect against SQL injection.
    ///
    /// Usage:
    ///
    ///     // No bindings
    ///     let rows = try await db.query("SELECT * FROM users where id = 1")
    ///     print("Got \(rows.count) users.")
    ///
    ///     // Bindings, to protect against SQL injection.
    ///     let rows = try await db.query("SELECT * FROM users where id = ?", values = [.int(1)])
    ///     print("Got \(rows.count) users.")
    ///
    /// - Parameters:
    ///   - sql: The SQL string with '?'s denoting variables that
    ///     should be parameterized.
    ///   - values: An array, `[SQLValue]`, that will replace the
    ///     '?'s in `sql`. Ensure there are the same amnount of values
    ///     as there are '?'s in `sql`.
    /// - Returns: The database rows returned by the query.
    @discardableResult
    func query(_ sql: String, values: [SQLValue]) async throws -> [SQLRow]
    
    /// Run a raw, not parametrized SQL string.
    ///
    /// - Returns: The rows returned by the query.
    @discardableResult
    func raw(_ sql: String) async throws -> [SQLRow]
    
    /// Runs a transaction on the database, using the given closure.
    /// All database queries in the closure are executed atomically.
    ///
    /// Uses START TRANSACTION; and COMMIT; under the hood.
    ///
    /// - Parameter action: The action to run atomically.
    /// - Returns: The return value of the transaction.
    @discardableResult
    func transaction<T>(_ action: @escaping (DatabaseProvider) async throws -> T) async throws -> T
    
    /// Called when the database connection will shut down.
    func shutdown() throws
}
