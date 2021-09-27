import Foundation
import PostgresKit

/// Used for interacting with an SQL database. This class is an
/// injectable `Service` so you can register the default one
/// via `Database.config(default: .postgres())`.
public final class Database: Service {
    /// The driver of this database.
    let driver: DatabaseDriver
    
    /// Any migrations associated with this database, whether applied
    /// yet or not.
    public var migrations: [Migration] = []
    
    /// Create a database backed by the given driver.
    ///
    /// - Parameter driver: The driver.
    public init(driver: DatabaseDriver) {
        self.driver = driver
    }
    
    /// Start a QueryBuilder query on this database. See `Query` or
    /// QueryBuilder guides.
    ///
    /// Usage:
    /// ```swift
    /// if let row = try await database.query().from("users").where("id" == 1).first() {
    ///     print("Got a row with fields: \(row.allColumns)")
    /// }
    /// ```
    ///
    /// - Returns: A `Query` builder.
    public func query() -> Query {
        Query(database: driver)
    }
    
    /// Run a parameterized query on the database. Parameterization
    /// helps protect against SQL injection.
    ///
    /// Usage:
    /// ```swift
    /// // No bindings
    /// let rows = try await db.rawQuery("SELECT * FROM users where id = 1")
    /// print("Got \(rows.count) users.")
    ///
    /// // Bindings, to protect against SQL injection.
    /// let rows = db.rawQuery("SELECT * FROM users where id = ?", values = [.int(1)])
    /// print("Got \(rows.count) users.")
    /// ```
    ///
    /// - Parameters:
    ///   - sql: The SQL string with '?'s denoting variables that
    ///     should be parameterized.
    ///   - values: An array, `[DatabaseValue]`, that will replace the
    ///     '?'s in `sql`. Ensure there are the same amnount of values
    ///     as there are '?'s in `sql`.
    /// - Returns: The database rows returned by the query.
    public func rawQuery(_ sql: String, values: [DatabaseValue] = []) async throws -> [DatabaseRow] {
        try await driver.runRawQuery(sql, values: values)
    }
    
    /// Runs a transaction on the database, using the given closure.
    /// All database queries in the closure are executed atomically.
    ///
    /// Uses START TRANSACTION; and COMMIT; under the hood.
    ///
    /// - Parameter action: The action to run atomically.
    /// - Returns: The return value of the transaction.
    public func transaction<T>(_ action: @escaping (Database) async throws -> T) async throws -> T {
        try await driver.transaction { try await action(Database(driver: $0)) }
    }
    
    /// Called when the database connection will shut down.
    ///
    /// - Throws: Any error that occurred when shutting down.
    public func shutdown() throws {
        try driver.shutdown()
    }
    
    /// Returns a `Query` for the default database.
    public static func query() -> Query {
        Query(database: Database.default.driver)
    }
}

/// A generic type to represent any database you might be interacting
/// with. Currently, the only two implementations are
/// `PostgresDatabase` and `MySQLDatabase`. The QueryBuilder and Rune
/// ORM are built on top of this abstraction.
public protocol DatabaseDriver {
    /// Functions around compiling SQL statments for this database's
    /// SQL dialect when using the QueryBuilder or Rune.
    var grammar: Grammar { get }
    
    /// Run a parameterized query on the database. Parameterization
    /// helps protect against SQL injection.
    ///
    /// Usage:
    /// ```swift
    /// // No bindings
    /// let rows = try await db.rawQuery("SELECT * FROM users where id = 1")
    /// print("Got \(rows.count) users.")
    ///
    /// // Bindings, to protect against SQL injection.
    /// let rows = db.rawQuery("SELECT * FROM users where id = ?", values = [.int(1)])
    /// print("Got \(rows.count) users.")
    /// ```
    ///
    /// - Parameters:
    ///   - sql: The SQL string with '?'s denoting variables that
    ///     should be parameterized.
    ///   - values: An array, `[DatabaseValue]`, that will replace the
    ///     '?'s in `sql`. Ensure there are the same amnount of values
    ///     as there are '?'s in `sql`.
    /// - Returns: The database rows returned by the query.
    func runRawQuery(_ sql: String, values: [DatabaseValue]) async throws -> [DatabaseRow]
    
    /// Runs a transaction on the database, using the given closure.
    /// All database queries in the closure are executed atomically.
    ///
    /// Uses START TRANSACTION; and COMMIT; under the hood.
    ///
    /// - Parameter action: The action to run atomically.
    /// - Returns: The return value of the transaction.
    func transaction<T>(_ action: @escaping (DatabaseDriver) async throws -> T) async throws -> T
    
    /// Called when the database connection will shut down.
    func shutdown() throws
}
