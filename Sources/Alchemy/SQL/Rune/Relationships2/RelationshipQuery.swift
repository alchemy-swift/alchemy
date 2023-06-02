extension Model {
    var row: SQLRow {
        fatalError()
    }

    func cache<To: RelationAllowed>(hashValue: Int, value: To) {
        fatalError()
    }

    func checkCache<To: RelationAllowed>(hashValue: Int) -> To? {
        fatalError()
    }

    func cacheExists(hashValue: Int) -> Bool {
        fatalError()
    }
}

/// One of these per eager loadable relationship.
public final class ModelRelationship<From: Model, To: RelationAllowed> {
    let from: From
    let query: RelationshipQuery

    init(from: From, query: RelationshipQuery) {
        self.from = from
        self.query = query
    }

    func get() async throws -> To {
        let results = try await query.execute(input: [from.row])[0]
        let models = try results.mapDecode(To.M.self)
        let value = try To.from(array: models)
        from.cache(hashValue: query.hashValue, value: value)
        return value
    }

    func eagerLoad(on input: [From]) async throws {
        let inputRows = input.map(\.row)
        let rows = try await query.execute(input: inputRows)
        let values = try rows
            .map { try $0.mapDecode(To.M.self) }
            .map { try To.from(array: $0) }
        for (model, results) in zip(input, values) {
            model.cache(hashValue: query.hashValue, value: results)
        }
    }
}

struct Key: Hashable {
    let table: String
    let column: String
}

/// Describes a relationship between SQL tables. A single query.
final class RelationshipQuery: Hashable {
    let from: Key
    let to: Key

    init(from: Key, to: Key) {
        self.from = from
        self.to = to
    }

    /// Execute the relationship given the input rows. Always returns an array
    /// the same length as the input array.
    func execute(input: [SQLRow]) async throws -> [[SQLRow]] {
        let inputValues = input.map(\.[from.column])
        let results = try await DB
            .from(to.table)
            .where(to.column, in: inputValues)
            .select()

        let resultsByToColumn = results.grouped(by: \.[to.column])
        return inputValues.map { resultsByToColumn[$0] ?? [] }
    }

    // MARK: - Hashable

    public static func == (lhs: RelationshipQuery, rhs: RelationshipQuery) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(from)
        hasher.combine(to)
    }
}

extension Query where Result: EagerLoadable {
    public func with2<T: RelationAllowed>(
        _ relationship: @escaping (Result) -> Result.Relationship<T>,
        nested: @escaping ((Result.Relationship<T>) -> Result.Relationship<T>) = { $0 }
    ) -> Self {
        didLoad { models in
            guard let first = models.first else {
                return
            }

            let query = nested(relationship(first))
            try await query.eagerLoad(on: models)
        }
    }
}

extension ModelRelationship {
    static func has(_ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Key(table: From.tableName, column: from ?? From.idKey)
        let toKey = Key(table: To.M.tableName, column: to ?? From.referenceKey)
        let query = RelationshipQuery(from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }

    static func belongs(_ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Key(table: From.tableName, column: from ?? To.M.referenceKey)
        let toKey = Key(table: To.M.tableName, column: to ?? To.M.idKey)
        let query = RelationshipQuery(from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }
}

extension Model {
    public typealias Relationship<To: RelationAllowed> = ModelRelationship<Self, To>

    public func hasMany<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<[To]> {
        return .has(self, from: fromKey, to: toKey)
    }

    public func hasOne<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To> {
        return .has(self, from: fromKey, to: toKey)
    }

    public func hasOne<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To?> {
        return .has(self, from: fromKey, to: toKey)
    }

    public func belongsTo<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To> {
        return .belongs(self, from: fromKey, to: toKey)
    }

    public func belongsTo<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To?> {
        return .belongs(self, from: fromKey, to: toKey)
    }
}

// MARK: Deprecated / Scratch

private class __RelationshipQueryDeprecated<From: EagerLoadable, To: RelationAllowed>: Query<To.M> {
    var fromModel: From
    var fromKeyOverride: String?
    var toKeyOverride: String?
    var relation: Relation

    // MARK: Through Scratch

    var throughs: [Through] = []

    func fromKey(to: Keys?) -> String {
        fromKeyOverride ?? relation.defaultFromKey(from: .model(From.self), to: to ?? .model(To.M.self))
    }

    func toKey(from: Keys?) -> String {
        toKeyOverride ?? relation.defaultToKey(from: from ?? .model(From.self), to: .model(To.M.self))
    }

    init(db: Database = DB, fromModel: From, fromKey: String?, toKey: String?, relation: Relation) {
        self.fromModel = fromModel
        self.fromKeyOverride = fromKey
        self.toKeyOverride = toKey
        self.relation = relation
        super.init(db: db, table: To.M.tableName)
    }

    // Through Model

    // SOLID
    public func through(_ model: (some Model).Type, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        through(model.tableName, from: fromKey, to: toKey)
    }

    // SOLID
    public func throughPivot(_ model: (some Model).Type, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        throughPivot(model.tableName, from: fromKey, to: toKey)
    }

    // Through table

    // SOLID
    public func throughPivot(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        self.relation = .pivot
        return through(table, from: fromKey ?? From.referenceKey, to: toKey ?? To.M.referenceKey)
    }

    // SOLID
    public func through(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        let through = Through(table: table,
                              fromKeyOverride: fromKey,
                              toKeyOverride: toKey,
                              tableKeys: .table(table, from: From.self),
                              relation: .has)
        throughs.append(through)
        return self
    }
}

struct Keys: Equatable {
    let idKey: String
    let referenceKey: String

    static func model(_ model: (some Model).Type) -> Keys {
        Keys(
            idKey: model.idKey,
            referenceKey: model.referenceKey
        )
    }

    static func table(_ table: String, from: (some Model).Type) -> Keys {
        Keys(
            idKey: from.keyMapping.map(input: "Id"),
            referenceKey: from.keyMapping.map(input: table.singularized + "Id")
        )
    }
}

/// The kind of relationship. Used only to determine to/from key defaults.
enum Relation {
    /// `From` is a child of `To`.
    case belongsTo
    /// `From` is a parent of `To`.
    case has
    /// `From` and `To` are parents of a separate pivot table.
    case pivot

    func defaultFromKey(from: Keys, to: Keys) -> String {
        switch self {
        case .has, .pivot:
            return from.idKey
        case .belongsTo:
            return to.referenceKey
        }
    }

    func defaultToKey(from: Keys, to: Keys) -> String {
        switch self {
        case .belongsTo, .pivot:
            return to.idKey
        case .has:
            return from.referenceKey
        }
    }
}

public struct QueryStep {
    public let fromTable: String
    public let fromKey: String
    public let toTable: String
    public let toKey: String
}

/// Computes the relationship across another table.
struct Through: Hashable {
    /// The table through which the relationship should go.
    let table: String
    /// Any user provided `fromKey`.
    let fromKeyOverride: String?
    /// Any user provided `toKey`.
    let toKeyOverride: String?
    /// The key defaults for the table.
    let tableKeys: Keys
    /// The type of relationship this through table is to the from table.
    let relation: Relation

    /// The from key to use when constructing the query.
    func fromKey(fromKeys: Keys) -> String {
        fromKeyOverride ?? relation.defaultToKey(from: fromKeys, to: tableKeys)
    }

    /// The to key to use when constructing the query.
    func toKey(toKeys: Keys) -> String {
        toKeyOverride ?? relation.defaultFromKey(from: tableKeys, to: toKeys)
    }

    func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(table)
        hasher.combine(fromKeyOverride)
        hasher.combine(toKeyOverride)
    }
}
