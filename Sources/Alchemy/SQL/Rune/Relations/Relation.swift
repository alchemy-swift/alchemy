public class Relation<From: Model, To: OneOrMany>: Query<To.M> {
    struct Through {
        let table: String
        let from: SQLKey
        let to: SQLKey
    }

    // Might be able to use the SQL query intead?
    var cacheKey: String {
        var key = "\(name(of: Self.self))_\(fromKey)_\(toKey)"
        for through in throughs {
            key.append("_\(through.table)_\(through.from)_\(through.to)")
        }

        return key
    }

    /// The model instance this relation was accessed from.
    let from: From
    var fromKey: SQLKey
    var toKey: SQLKey
    private var lookupKey: String
    private var throughs: [Through]

    public init(db: Database, from: From, fromKey: SQLKey, toKey: SQLKey) {
        self.from = from
        self.fromKey = fromKey
        self.toKey = toKey
        self.throughs = []
        self.lookupKey = "\(toKey)"
        super.init(db: db, table: To.M.table)
    }

    /// Execute the relationship given the input rows. Always returns an array
    /// the same length as the input array.
    public func fetch(for models: [From]) async throws -> [To] {
        setJoins()
        let fromKeys = models.map(\.row["\(fromKey)"])
        let results = try await `where`(lookupKey, in: fromKeys).get(columns)
        let resultsByLookup = results.grouped(by: \.row[lookupKey])
        return try fromKeys
            .map { resultsByLookup[$0] ?? [] }
            .map { try To(models: $0) }
    }

    private func setJoins() {
        var nextKey = "\(table).\(toKey)"
        for through in throughs.reversed() {
            join(table: through.table, first: "\(through.table).\(through.to)", second: nextKey)
            nextKey = "\(through.table).\(through.from)"
        }
    }

    @discardableResult
    func _through(table: String, from: SQLKey, to: SQLKey) -> Self {
        if throughs.isEmpty {
            lookupKey = "\(table).\(from)"
            columns.append(lookupKey)
        }

        throughs.append(Through(table: table, from: from, to: to))
        return self
    }

    public final func eagerLoad(on models: [From]) async throws {
        let values = try await fetch(for: models)
        for (model, results) in zip(models, values) {
            model.cache(key: cacheKey, value: results)
        }
    }

    public final func get() async throws -> To {
        if let cached = try from.checkCache(key: cacheKey, To.self) {
            return cached
        }

        let value = try await fetch(for: [from])[0]
        from.cache(key: cacheKey, value: value)
        return value
    }

    public final func callAsFunction() async throws -> To {
        try await get()
    }
}

// MARK: - Eager Loading

extension Query where Result: Model {
    public func with<To: OneOrMany, T: Relation<Result, To>>(
        _ relationship: @escaping (Result) -> T,
        nested: @escaping ((T) -> T) = { $0 }
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

// MARK: - Compound Eager Loading

extension Relation where To: OneOrMany {
    public subscript<T: OneOrMany>(dynamicMember relationship: KeyPath<To.M, Relation<To.M, T>>) -> Relation<From, T> {
        // Could add a through, however it would be great to eager load the intermidiary relationship.
        fatalError()
    }
}
