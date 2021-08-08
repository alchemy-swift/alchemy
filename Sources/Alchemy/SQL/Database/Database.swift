import Foundation
import PostgresKit

public final class Database: Service {
    let driver: DatabaseDriver
    
    /// Any migrations associated with this database, whether applied
    /// yet or not.
    public var migrations: [Migration] = []
    
    var grammar: Grammar { driver.grammar }
    
    init(driver: DatabaseDriver) {
        self.driver = driver
    }
    
    /// Start a QueryBuilder query on this database. See `Query` or
    /// QueryBuilder guides.
    ///
    /// Usage:
    /// ```swift
    /// database.query()
    ///     .from(table: "users")
    ///     .where("id" == 1)
    ///     .first()
    ///     .whenSuccess { row in
    ///         guard let row = row else {
    ///             return print("No row found :(")
    ///         }
    ///
    ///         print("Got a row with fields: \(row.allColumns)")
    ///     }
    /// ```
    ///
    /// - Returns: The start of a QueryBuilder `Query`.
    public func query() -> Query {
        Query(database: driver)
    }
    
    /// Run a parameterized query on the database. Parameterization
    /// helps protect against SQL injection.
    ///
    /// Usage:
    /// ```swift
    /// // No bindings
    /// db.runRawQuery("SELECT * FROM users where id = 1")
    ///     .whenSuccess { rows
    ///         guard let first = rows.first else {
    ///             return print("No rows found :(")
    ///         }
    ///
    ///         print("Got a user row with columns \(rows.allColumns)!")
    ///     }
    ///
    /// // Bindings, to protect against SQL injection.
    /// db.runRawQuery("SELECT * FROM users where id = ?", values = [.int(1)])
    ///     .whenSuccess { rows
    ///         ...
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - sql: The SQL string with '?'s denoting variables that
    ///     should be parameterized.
    ///   - values: An array, `[DatabaseValue]`, that will replace the
    ///     '?'s in `sql`. Ensure there are the same amnount of values
    ///     as there are '?'s in `sql`.
    /// - Returns: An `EventLoopFuture` of the rows returned by the
    ///   query.
    public func runRawQuery(_ sql: String, values: [DatabaseValue] = []) -> EventLoopFuture<[DatabaseRow]> {
        driver.runRawQuery(sql, values: values)
    }
    
    /// Runs a transaction on the database, using the given closure.
    /// All database queries in the closure are executed atomically.
    ///
    /// Uses START TRANSACTION; and COMMIT; under the hood.
    public func transaction<T>(_ action: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        driver.transaction { action(Database(driver: $0)) }
    }
    
    /// Called when the database connection will shut down.
    ///
    /// - Throws: Any error that occurred when shutting down.
    func shutdown() throws {
        try driver.shutdown()
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
    /// db.runRawQuery("SELECT * FROM users where id = 1")
    ///     .whenSuccess { rows
    ///         guard let first = rows.first else {
    ///             return print("No rows found :(")
    ///         }
    ///
    ///         print("Got a user row with columns \(rows.allColumns)!")
    ///     }
    ///
    /// // Bindings, to protect against SQL injection.
    /// db.runRawQuery("SELECT * FROM users where id = ?", values = [.int(1)])
    ///     .whenSuccess { rows
    ///         ...
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - sql: The SQL string with '?'s denoting variables that
    ///     should be parameterized.
    ///   - values: An array, `[DatabaseValue]`, that will replace the
    ///     '?'s in `sql`. Ensure there are the same amnount of values
    ///     as there are '?'s in `sql`.
    /// - Returns: An `EventLoopFuture` of the rows returned by the
    ///   query.
    func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]>
    
    /// Runs a transaction on the database, using the given closure.
    /// All database queries in the closure are executed atomically.
    ///
    /// Uses START TRANSACTION; and COMMIT; under the hood.
    func transaction<T>(_ action: @escaping (DatabaseDriver) -> EventLoopFuture<T>) -> EventLoopFuture<T>
    
    /// Called when the database connection will shut down.
    ///
    /// - Throws: Any error that occurred when shutting down.
    func shutdown() throws
}
