import Foundation
import Pluralize

public protocol Model: ModelBase, Codable {}

/// An ActiveRecord-esque type used for modeling a table in a
/// relational database. Contains many extensions for making
/// database queries, supporting relationships & much more.
public protocol ModelBase: Identifiable, RelationshipAllowed {
    /// The type of this object's primary key.
    associatedtype Identifier: PrimaryKey
    
    /// The identifier / primary key of this type.
    var id: Self.Identifier? { get set }
    
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
    
    /// How should the Swift `CodingKey`s be mapped to database
    /// columns? Defaults to `.convertToSnakeCase`. Can be
    /// overridden on a per-type basis.
    static var keyMapping: DatabaseKeyMapping { get }
    
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
    
    init(row: SQLRow) throws // Auto filled in for codable models, in extension
    
    func toSQLRow() throws -> SQLRow // Auto filled in for codable models, in extension
    
    /// Defines any custom behavior when loading relationships.
    ///
    /// - Parameter mapper: An object with which to customize
    ///   relationship loading behavior.
    static func mapRelations(_ mapper: RelationshipMapper<Self>)
}

extension ModelBase where Self: Codable {
    // Auto filled in for codable models, in extension
    public init(row: SQLRow) throws {
        self = try row.decode(Self.self)
    }
    
    // Auto filled in for codable models, in extension
    public func toSQLRow() throws -> SQLRow {
        try SQLRowEncoder(keyMapping: Self.keyMapping, jsonEncoder: Self.jsonEncoder).sqlRow(for: self)
    }
}

extension ModelBase {
    public static var tableName: String {
        let typeName = String(describing: Self.self)
        let mapped = keyMapping.map(input: typeName)
        return mapped.pluralized
    }
    
    public static var keyMapping: DatabaseKeyMapping {
        .convertToSnakeCase
    }
    
    public static var jsonDecoder: JSONDecoder {
        JSONDecoder()
    }
    
    public static var jsonEncoder: JSONEncoder {
        JSONEncoder()
    }
    
    public static func mapRelations(_ mapper: RelationshipMapper<Self>) {}
    
    /// Unwraps the id of this object or throws if it is nil.
    ///
    /// - Throws: A `DatabaseError` if the `id` of this object is nil.
    /// - Returns: The unwrapped `id` value of this database object.
    public func getID() throws -> Self.Identifier {
        guard let id = id else {
            throw DatabaseError("Object of type \(type(of: self)) had a nil id.")
        }
        
        return id
    }
}
