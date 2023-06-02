/// One of these per eager loadable relationship.
public final class ModelRelationship<From: Model, To: RelationAllowed> {
    let from: From
    let query: RelationshipQuery

    init(from: From, query: RelationshipQuery) {
        self.from = from
        self.query = query
    }

    func eagerLoad(on input: [From]) async throws {
        let inputRows = input.map(\.row)
        let rows = try await query.execute(input: inputRows)
        let values = try rows
            .map { try $0.mapDecode(To.M.self) }
            .map { try To(models: $0) }
        for (model, results) in zip(input, values) {
            model.cache(hashValue: query.hashValue, value: results)
        }
    }

    public func get() async throws -> To {
        guard let value: To = try from.checkCache(hashValue: query.hashValue) else {
            let results = try await query.execute(input: [from.row])[0]
            let models = try results.mapDecode(To.M.self)
            let value = try To(models: models)
            from.cache(hashValue: query.hashValue, value: value)
            return value
        }

        return value
    }

    public func callAsFunction() async throws -> To {
        try await get()
    }
}

struct Key: Hashable {
    let table: String
    /// If nil, the key will be inferred.
    let explicitColumn: String?

    func column(for: RelationshipQuery.Kind) -> String {
        explicitColumn ?? "FOO"
    }
}

/// Describes a relationship between SQL tables. A single query.
final class RelationshipQuery: Hashable {
    /// Used to infer default keys.
    enum Kind {
        case has
        case belongs
    }

    private struct Through {
        // Ensure key mapping is used to find defaults.
        let table: String
        let from: String?
        let to: String?
        let isPivot: Bool = false
    }

    private let type: Kind
    private let from: Key
    private let to: Key
    private var throughs: [Through] = []
    private var wheres: [SQLWhere] = []

    init(type: Kind, from: Key, to: Key) {
        self.type = type
        self.from = from
        self.to = to
    }

    func addThrough(_ table: String, from: String? = nil, to: String? = nil) {
        /*
         MAY NEED TO CHANGE OTHERS
         1. `from` or `to` if through pivot.
         2. `joins.previous` if through pivot AND override not set.
         3. `from` if through AND belongsTo
         4. `to` if through AND has
         5. `joins.previous` if through AND belongTo
         */

        // It would be nice if this were just a join added to a query. The issue
        // comes from inferring key types. The logic will need to look "back"
        // and see which keys have been set as a default or inferred. There's no
        // way given an SQLJoin to see if the key was set manually or
        // inferred.

        // 1. Infer the keys.
        // 2. Add the join.
        // 3. Change `to` defaults if it's a pivot.
        throughs.append(Through(table: table, from: from, to: to))
    }

    func addWhere(_ where: SQLWhere) {
        wheres.append(`where`)
    }

    /// Execute the relationship given the input rows. Always returns an array
    /// the same length as the input array.
    func execute(input: [SQLRow]) async throws -> [[SQLRow]] {
        var query = DB.from(to.table)

        for through in throughs {
            let join = SQLJoin(type: .left, joinTable: through.table)
                .on(first: through.from ?? "foo", op: .equals, second: through.to ?? "foo")
            query = query.join(join)
        }

        for `where` in wheres {
            query = query.where(`where`)
        }

        let fromColumn = from.column(for: type)
        let toColumn = to.column(for: type)
        let inputValues = try input.map { try $0.require(fromColumn) }
        let results = try await query
            .where(toColumn, in: inputValues)
            .select(["\(to.table).*", fromColumn])

        let resultsByToColumn = results.grouped(by: \.[fromColumn])
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

extension Query where Result: Model {
    public func with<T: RelationAllowed>(
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
    fileprivate static func has(_ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Key(table: From.tableName, explicitColumn: from)
        let toKey = Key(table: To.M.tableName, explicitColumn: to)
        let query = RelationshipQuery(type: .has, from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }

    fileprivate static func belongs(_ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Key(table: From.tableName, explicitColumn: from)
        let toKey = Key(table: To.M.tableName, explicitColumn: to)
        let query = RelationshipQuery(type: .belongs, from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }
}

// MARK: - Default Relationships

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

// MARK: - Relationship Modifiers

extension ModelRelationship {

    public func through(_ table: String, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        query.addThrough(table, from: from, to: to)
        return self
    }

    public func throughPivot(_ table: String, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        query.addThrough(table, from: from, to: to)
        return self
    }

    public func `where`(_ where: SQLWhere) {
        query.addWhere(`where`)
    }

    public subscript<T: RelationAllowed>(dynamicMember relationship: KeyPath<To.M, To.M.Relationship<T>>) -> From.Relationship<T> {
        // Could add a through, however it would be great to eager load the intermidiary relationship.
        fatalError()
    }
}
