public class Relation<From: Model, To: OneOrMany>: Query<To.M> {
    struct Through {
        let table: String
        var from: SQLKey
        var to: SQLKey
    }

    /// The model instance this relation was accessed from.
    let from: From
    var fromKey: SQLKey
    var toKey: SQLKey
    var lookupKey: String
    var throughs: [Through]

    private var cacheKey: String {
        let key = "\(name(of: Self.self))_\(fromKey)_\(toKey)"
        let throughKeys = throughs.map { "\($0.table)_\($0.from)_\($0.to)" }
        let whereKeys = wheres.map { "\($0.hashValue)" }
        return ([key] + throughKeys + whereKeys).joined(separator: "_")
    }

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
            columns.append("\(lookupKey) as \"\(lookupKey)\"")
        }

        throughs.append(Through(table: table, from: from, to: to))
        return self
    }

    public final func eagerLoad(on models: [From]) async throws {
        let key = cacheKey
        let values = try await fetch(for: models)
        for (model, results) in zip(models, values) {
            model.cache(key: key, value: results)
        }
    }

    public final func get() async throws -> To {
        let key = cacheKey
        if let cached = try from.checkCache(key: key, To.self) {
            return cached
        }

        let value = try await fetch(for: [from])[0]
        from.cache(key: key, value: value)
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
