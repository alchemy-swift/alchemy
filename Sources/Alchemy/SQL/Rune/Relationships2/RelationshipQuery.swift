extension Model {
    var row: SQLRow {
        id.storage.row
    }

    func cache<To: RelationAllowed>(hashValue: Int, value: To) {
        id.storage.relationships[hashValue] = value
    }

    func checkCache<To: RelationAllowed>(hashValue: Int) throws -> To? {
        guard let value = id.storage.relationships[hashValue] else {
            return nil
        }

        guard let value = value as? To else {
            throw RuneError("Relationship type mismatch!")
        }

        return value
    }

    func cacheExists(hashValue: Int) -> Bool {
        id.storage.relationships[hashValue] != nil
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
        let inputValues = try input.map { try $0.require(from.column) }
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

extension Query where Result: Model {
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

    // TODO: DO THIS! ALSO SET DATABASE

    func through() {
        // don't forget to allow for table string or models; for table string be sure to use the key mapping.
        // for implementation just add a join
    }

    func throughPivot() {
        // don't forget to allow for table string or models; for table string be sure to use the key mapping.
        // for implementation just add a join
    }
}
