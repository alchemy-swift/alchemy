import Foundation
import Pluralize

/// An ActiveRecord-esque type used for modeling a table in a
/// relational database. Contains many extensions for making
/// database queries, supporting relationships & much more.
public protocol Model: Codable, ModelBase, ModelOrOptional {}

/// The Core Model type, useful if you don't want your model to conform to
/// Codable.
public protocol ModelBase: Identifiable, SQLQueryResult {
    /// The type of this object's primary key.
    associatedtype Identifier: PrimaryKey

    /// The identifier / primary key of this type.
    var id: PK<Self.Identifier> { get set }

    /// Convert this to an SQLRow for updating or inserting into a database.
    func toSQLRow() throws -> SQLRow

    /// The table with which this object is associated. Defaults to
    /// the type name, pluralized. Affected by `keyMapping`. This
    /// can be overridden for custom table names.
    ///
    /// ```swift
    /// struct User: Model {
    ///     static var tableName: String = "my_user_table"
    ///
    ///     var id: Int?
    ///     let name: String
    ///     let email: String
    /// }
    /// ```
    static var table: String { get }

    /// The primary key column of this table.
    static var primaryKey: String { get }

    /// The `JSONDecoder` to use when decoding any JSON fields of this
    /// type. A JSON field is any `Codable` field that doesn't have a
    /// corresponding `DatabaseValue`.
    ///
    /// Defaults to `JSONDecoder()`.
    static var jsonDecoder: JSONDecoder { get }

    /// The `JSONEncoder` to use when decoding any JSON fields of this
    /// type. A JSON field is any `Codable` field on this type that
    /// doesn't have a corresponding `DatabaseValue`.
    ///
    /// Defaults to `JSONEncoder()`.
    static var jsonEncoder: JSONEncoder { get }
}

extension ModelBase {
    public static var table: String { KeyMapping.snakeCase.encode("\(Self.self)").pluralized }
    public static var primaryKey: String { "id" }
    public static var jsonDecoder: JSONDecoder { JSONDecoder() }
    public static var jsonEncoder: JSONEncoder { JSONEncoder() }
}

extension ModelBase where Self: Codable {
    public init(row: SQLRow) throws {
        self = try row.decode(Self.self, keyMapping: .snakeCase, jsonDecoder: Self.jsonDecoder)
    }

    public func toSQLRow() throws -> SQLRow {
        try SQLRowEncoder(keyMapping: .snakeCase, jsonEncoder: Self.jsonEncoder).sqlRow(for: self)
    }
}
