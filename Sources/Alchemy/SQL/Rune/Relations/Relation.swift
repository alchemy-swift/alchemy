/*
 Checklist

 1. DONE BelongsTo
 2. DONE HasOne
 3. DONE HasMany
 4. DONE HasManyThrough
 5. DONE HasOneThrough
 6. DONE BelongsToMany
 7. DONE BelongsToThrough
 8. DONE Add multiple throughs
 9. DONE Eager Loading
 10 DONE Nested eager loading
 11. Add where to Relationship
 12. Infer keys (has = modify next to inference, belongs = modify last from inference)
 13. CRUD
 14. Subscript loading

 */

public class Relation<From: Model, To: OneOrMany>: Query<To.M> {
    /// Used when caching after eager loading. This should be unique per relationship. Might be able to use the SQL query intead.
    var cacheKey: String {
        // Infer with query?
        preconditionFailure("This should be overrided.")
    }

    /// The specific model this relation was accessed from.
    let from: From

    public init(db: Database, from: From) {
        self.from = from
        super.init(db: db, table: To.M.table)
    }

    /// Execute the relationship given the input rows. Always returns an array
    /// the same length as the input array.
    public func fetch(for models: [From]) async throws -> [To] {
        preconditionFailure("This should be overridden.")
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
