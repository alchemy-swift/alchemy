import Foundation

/// Used for interacting with an SQL database. This class is an
/// injectable `Service` so you can register the default one
/// via `Database.config(default: .postgres())`.
public final class Database: Service {
    /// The driver of this database.
    let driver: DatabaseDriver
    
    /// Any migrations associated with this database, whether applied
    /// yet or not.
    public var migrations: [Migration] = []
    
    /// Any seeders associated with this database.
    public var seeders: [Seeder] = []
    
    /// Create a database backed by the given driver.
    ///
    /// - Parameter driver: The driver.
    public init(driver: DatabaseDriver) {
        self.driver = driver
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
    ///   - values: An array, `[SQLValue]`, that will replace the
    ///     '?'s in `sql`. Ensure there are the same amount of values
    ///     as there are '?'s in `sql`.
    /// - Returns: The database rows returned by the query.
    public func query(_ sql: String, values: [SQLValue] = []) async throws -> [SQLRow] {
        try await driver.query(sql, values: values)
    }
    
    /// Runs a transaction on the database, using the given closure.
    /// All database queries in the closure are executed atomically.
    ///
    /// Uses START TRANSACTION; and COMMIT; or similar under the hood.
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
}
