import Foundation

/// A global singleton accessor & convenient typealias for a default database. A
/// lot of Alchemy functionality assumes existence of a default database, so
/// make sure to set one in your `Application.setup` function!
///
/// ```
/// // MyApplication.swift
/// func setup() {
///     DB.default = ...
///     ...
/// }
///
/// // Elsewhere
/// DB.default
///     .runRawQuery("select * from users;")
///     .whenSuccess { rows in
///         print("Got \(rows.count) results!")
///     }
/// ```
public typealias DB = DatabaseDefault

/// Struct for wrapping a default `Database` for convenient use. See `DB`.
public struct DatabaseDefault {
    /// A default singleton database.
    public static var `default`: Database {
        get {
            guard let _default = DatabaseDefault._default else {
                fatalError("A default `Database` has not been set up yet. You can do so via `DB.default = ...`")
            }
            
            return _default
        }
        set {
            DatabaseDefault._default = newValue
        }
    }
    
    /// Shorthand for starting a `QueryBuilder` query with `DB.default`.
    ///
    /// Usage:
    /// ```
    /// DB.query()
    ///     .from(table: "users")
    ///     .where("id" == 1)
    ///     .first()
    ///     .map { $0?.decode(User.self) }
    /// ```
    public static func query() -> Query {
        return DB.default.query()
    }
    
    /// Backing value so that the `default` wrapper can fatal with a helpful
    /// error message if a default value hasn't been set yet.
    private static var _default: Database?
}
