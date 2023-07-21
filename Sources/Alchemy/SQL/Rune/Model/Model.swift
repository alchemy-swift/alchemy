import Foundation
import Pluralize

public protocol Model: Codable, ModelBase, ModelOrOptional {}

extension Model {
    var row: SQLRow {
        id.storage.row
    }

    func cache<To>(key: String, value: To) {
        id.storage.relationships[key] = value
    }

    func checkCache<To>(key: String, _ type: To.Type = To.self) throws -> To? {
        guard let value = id.storage.relationships[key] else {
            return nil
        }

        guard let value = value as? To else {
            throw RuneError("Relationship type mismatch!")
        }

        return value
    }

    func exists(key: String) -> Bool {
        id.storage.relationships[key] != nil
    }
}

/// An ActiveRecord-esque type used for modeling a table in a
/// relational database. Contains many extensions for making
/// database queries, supporting relationships & much more.
public protocol ModelBase: Identifiable, SQLQueryResult {
    /// The type of this object's primary key.
    associatedtype Identifier: PrimaryKey

    /// The identifier / primary key of this type.
    var id: PK<Self.Identifier> { get set }

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
    static var tableName: String { get }

    static var idKey: String { get }

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

    func toSQLRow() throws -> SQLRow // Auto filled in for codable models, in extension
}

extension ModelBase where Self: Codable {
    // Auto filled in for codable models, in extension
    public init(row: SQLRow) throws {
        self = try row.decode(Self.self, keyMapping: .snakeCase, jsonDecoder: Self.jsonDecoder)
    }
    
    // Auto filled in for codable models, in extension
    public func toSQLRow() throws -> SQLRow {
        try SQLRowEncoder(keyMapping: .snakeCase, jsonEncoder: Self.jsonEncoder).sqlRow(for: self)
    }
}

extension ModelBase {
    public static var tableName: String {
        let typeName = String(describing: Self.self)
        let mapped = KeyMapping.snakeCase.encode(typeName)
        return mapped.pluralized
    }

    public static var referenceKey: String {
        let key = Self.tableName.singularized + "Id"
        return KeyMapping.snakeCase.encode(key)
    }

    public static var idKey: String {
        "id"
    }
    
    public static var jsonDecoder: JSONDecoder {
        JSONDecoder()
    }
    
    public static var jsonEncoder: JSONEncoder {
        JSONEncoder()
    }
    
    /// Unwraps the id of this object or throws if it is nil.
    ///
    /// - Throws: A `DatabaseError` if the `id` of this object is nil.
    /// - Returns: The unwrapped `id` value of this database object.
    public func getID() throws -> Self.Identifier {
        guard let id = id.value else {
            throw DatabaseError("Object of type \(type(of: self)) had a nil id.")
        }
        
        return id
    }
}
