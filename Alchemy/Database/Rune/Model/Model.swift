import Pluralize

/// An ActiveRecord-esque type used for modeling a table in a relational
/// database. Contains many extensions for making database queries, 
/// supporting relationships & more.
///
/// Use @Model to apply this protocol.
public protocol Model: Identifiable, QueryResult, ModelOrOptional {
    /// The type of this object's primary key.
    associatedtype PrimaryKey: PrimaryKeyProtocol

    /// The identifier of this model
    var id: PrimaryKey { get nonmutating set }

    /// Storage for model metadata (relationships, original row, etc).
    var storage: Storage { get }

    /// Convert this to an SQLRow for updating or inserting into a database.
    func fields() throws -> SQLFields

    /// The database on which this model is saved & queried by default.
    static var database: Database { get }

    /// The table with which this object is associated. Defaults to
    /// the type name, pluralized and in snake case.
    static var table: String { get }

    /// The primary key column of this table. Defaults to `"id"`.
    static var primaryKey: String { get }

    /// The keys to to check for conflicts on when UPSERTing. Defaults to 
    /// `[Self.primaryKey]`.
    static var upsertConflictKeys: [String] { get }

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
    static func query(on db: Database) -> Query<Self>
}

extension Model {
    public static var database: Database { DB }
    public static var keyMapping: KeyMapping { database.keyMapping }
    public static var table: String { keyMapping.encode("\(Self.self)").pluralized }
    public static var primaryKey: String { "id" }
    public static var upsertConflictKeys: [String] { [primaryKey] }
    public static var jsonDecoder: JSONDecoder { JSONDecoder() }
    public static var jsonEncoder: JSONEncoder { JSONEncoder() }

    /// Begin a `Query<Self>` from a given database.
    ///
    /// - Parameter database: The database to run the query on.
    ///   Defaults to `Database.default`.
    /// - Returns: A builder for building your query.
    public static func query(on db: Database = database) -> Query<Self> {
        db.table(Self.self)
    }

    public static func on(_ database: Database) -> Query<Self> {
        query(on: database)
    }
}

extension Model where Self: Codable {
    public init(row: SQLRow) throws {
        self = try row.decode(Self.self, keyMapping: Self.keyMapping, jsonDecoder: Self.jsonDecoder)
    }

    public func fields() throws -> SQLFields {
        try sqlFields(keyMapping: Self.keyMapping, jsonEncoder: Self.jsonEncoder)
    }
}

extension Encodable {
    func sqlFields(keyMapping: KeyMapping = .snakeCase, jsonEncoder: JSONEncoder = JSONEncoder()) throws -> SQLFields {
        try SQLRowEncoder(keyMapping: keyMapping, jsonEncoder: jsonEncoder).fields(for: self)
    }
}

extension Database {
    public func table<M: Model>(_ model: M.Type, as alias: String? = nil) -> Query<M> {
        let tableName = alias.map { "\(model.table) AS \($0)" } ?? model.table
        return Query(db: self, table: tableName)
            .didLoad { try await M.didFetch($0) }
    }
}

extension SQLRow {
    /// Decode a `Model` type `M` from this row.
    public func decodeModel<M: Model>(_ type: M.Type = M.self) throws -> M {
        try M(row: self)
    }
}

extension Array where Element == SQLRow {
    public func decodeModels<M: Model>(_ type: M.Type) throws -> [M] {
        try map { try M(row: $0) }
    }
}
