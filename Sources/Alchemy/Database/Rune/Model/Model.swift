import Foundation
import Pluralize

/// An ActiveRecord-esque type used for modeling a table in a
/// relational database. Contains many extensions for making
/// database queries, supporting relationships & more.
public protocol Model: ModelBase, Codable, ModelOrOptional {}

/// The Core Model type, useful if you don't want your model to conform to
/// Codable.
public protocol ModelBase: Identifiable, QueryResult {
    /// The type of this object's primary key.
    associatedtype Identifier: PrimaryKey

    /// The identifier / primary key of this type.
    var id: PK<Identifier> { get set }

    /// Convert this to an SQLRow for updating or inserting into a database.
    func fields() throws -> [String: SQLConvertible]

    /// The table with which this object is associated. Defaults to
    /// the type name, pluralized and in snake case.
    static var table: String { get }

    /// The primary key column of this table. Defaults to `"id"`.
    static var primaryKey: String { get }

    /// The `JSONDecoder` to use when decoding any JSON fields of this
    /// type. A JSON field is any `Codable` field that doesn't have a
    /// corresponding `SQLValue`.
    ///
    /// Defaults to `JSONDecoder()`.
    static var jsonDecoder: JSONDecoder { get }

    /// The `JSONEncoder` to use when decoding any JSON fields of this
    /// type. A JSON field is any `Codable` field on this type that
    /// doesn't have a corresponding `SQLValue`.
    ///
    /// Defaults to `JSONEncoder()`.
    static var jsonEncoder: JSONEncoder { get }

    /// The default scope of this Model. Defaults to all rows on `table`.
    static func query(db: Database) -> Query<Self>
}

extension ModelBase {
    public static var table: String { KeyMapping.snakeCase.encode("\(Self.self)").pluralized }
    public static var primaryKey: String { "id" }
    public static var jsonDecoder: JSONDecoder { JSONDecoder() }
    public static var jsonEncoder: JSONEncoder { JSONEncoder() }

    /// Begin a `Query<Self>` from a given database.
    ///
    /// - Parameter database: The database to run the query on.
    ///   Defaults to `Database.default`.
    /// - Returns: A builder for building your query.
    public static func query(db: Database = DB) -> Query<Self> {
        db.table(Self.self)
    }
}

extension ModelBase where Self: Codable {
    public init(row: SQLRow) throws {
        self = try row.decode(Self.self, keyMapping: .snakeCase, jsonDecoder: Self.jsonDecoder)
    }

    public func fields() throws -> [String: SQLConvertible] {
        try SQLRowEncoder(keyMapping: .snakeCase, jsonEncoder: Self.jsonEncoder).fields(for: self)
    }
}

extension Model {
    // TODO: Re-enable this
    fileprivate static func didFetch(_ models: [Self]) async throws {
        try await ModelDidFetch(models: models).fire()
    }
}

extension Database {
    public func table<M: ModelBase>(_ model: M.Type, as alias: String? = nil) -> Query<M> {
        let tableName = alias.map { "\(model.table) AS \($0)" } ?? model.table
        return Query(db: self, table: tableName)
    }
}

extension SQLRow {
    /// Decode a `Model` type `M` from this row.
    public func decodeModel<M: ModelBase>(_ type: M.Type = M.self) throws -> M {
        try M(row: self)
    }
}

extension Array where Element == SQLRow {
    public func decodeModels<M: ModelBase>(_ type: M.Type) throws -> [M] {
        try map { try M(row: $0) }
    }
}
