import Foundation

/// An ActiveRecord-esque type used for modeling a table in a relational database. Has lots of
/// extensions for making database queries, supporting relationships & much more.
///
/// - Warning: To keep things elegant for the end user, a lot of Rune's under-the-hood querying and
///            saving rely on the compiler synthesized `Codable` functions of a `Model`,
///            `init(from: Decoder)` or `func encode(to: Encoder)`. Override those at your own risk!
///            You might be able to get away with it, but it could also break things in unexpected
///            ways.
public protocol Model: Codable, Identifiable, ModelMaybeOptional {
    /// The type of this object's primary key.
    associatedtype Identifier: PrimaryKey
    
    /// The identifier / primary key of this type.
    var id: Self.Identifier? { get set }
    
    /// The table with which this object is associated. Defaults to
    /// `String(describing: Self.self)` aka the name of the type. Can be
    /// overridden for custom table names.
    ///
    /// ```
    /// struct User: DatabaseCodable {
    ///     static var tableName: String = "my_user_table"
    ///
    ///     var id: Int?
    ///     let name: String
    ///     let email: String
    /// }
    /// ```
    static var tableName: String { get }
    
    /// How should the Swift `CodingKey`s be mapped to database columns?
    /// Defaults to `convertToSnakeCase`. Can be overridden on a per-type basis.
    static var keyMappingStrategy: DatabaseKeyMappingStrategy { get }
    
    /// The `JSONDecoder` to use when decoding any JSON fields of this type.
    /// A JSON field is any `Codable` field that doesn't have a corresponding
    /// `DatabaseValue`.
    ///
    /// Defaults to `JSONDecoder()`.
    static var jsonDecoder: JSONDecoder { get }
    
    /// The `JSONEncoder` to use when decoding any JSON fields of this type.
    /// A JSON field is any `Codable` field on this type that doesn't have a
    /// corresponding `DatabaseValue`.
    ///
    /// Defaults to `JSONEncoder()`.
    static var jsonEncoder: JSONEncoder { get }
}

extension Model {
    public static var tableName: String {
        String(describing: Self.self)
    }
    
    public static var keyMappingStrategy: DatabaseKeyMappingStrategy {
        .convertToSnakeCase
    }
    
    public static var jsonDecoder: JSONDecoder {
        JSONDecoder()
    }
    
    public static var jsonEncoder: JSONEncoder {
        JSONEncoder()
    }
    
    /// Unwraps the id of this object or throws if it is nil.
    ///
    /// - Throws: a `DatabaseError` if the `id` of this object is nil.
    /// - Returns: the unwrapped `id` value of this database object.
    public func getID() throws -> Self.Identifier {
        try self.id.unwrap(or: DatabaseError("Object of type \(type(of: self)) had a nil id."))
    }
}

/// Represents a type that may be a primary key in a database. Out of the box
/// `UUID`, `String` and `Int` are supported but you can easily support your
/// own by conforming to this protocol.
public protocol PrimaryKey: Hashable, Parameter, Codable {
    /// Initialize this value from a `DatabaseField`.
    ///
    /// - Throws: if there is an error decoding this type from the given
    ///           database value.
    /// - Parameter field: the field with which this type should be initialzed
    ///                    from.
    init(field: DatabaseField) throws
}

extension UUID: PrimaryKey {
    // MARK: PrimaryKey
    
    public init(field: DatabaseField) throws {
        self = try field.uuid()
    }
}

extension Int: PrimaryKey {
    // MARK: PrimaryKey
    
    public init(field: DatabaseField) throws {
        self = try field.int()
    }
}

extension String: PrimaryKey {
    // MARK: PrimaryKey
    
    public init(field: DatabaseField) throws {
        self = try field.string()
    }
}
