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
 9. Add where to Relationship
 10. Infer keys (has = modify next to inference, belongs = modify last from inference)
 11. CRUD
 12. Subscript loading

 */

public protocol Relation<From, To> {
    associatedtype From: Model
    associatedtype To

    /// Used when caching after eager loading. This should be unique per relationship. Might be able to use the SQL query intead.
    var cacheKey: String { get }

    /// The specific model this relation was accessed from.
    var from: From { get }

    /// Execute the relationship given the input rows. Always returns an array
    /// the same length as the input array.
    func fetch(for models: [From]) async throws -> [To]
}

extension Relation {
    public func eagerLoad(on models: [From]) async throws {
        let values = try await fetch(for: models)
        for (model, results) in zip(models, values) {
            model.cache(key: cacheKey, value: results)
        }
    }

    public func get() async throws -> To {
        if let cached = try from.checkCache(key: cacheKey, To.self) {
            return cached
        }

        let value = try await fetch(for: [from])[0]
        from.cache(key: cacheKey, value: value)
        return value
    }

    public func callAsFunction() async throws -> To {
        try await get()
    }
}
