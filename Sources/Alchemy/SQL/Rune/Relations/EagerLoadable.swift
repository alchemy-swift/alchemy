@dynamicMemberLookup
public protocol EagerLoadable<From, To> {
    associatedtype From: Model
    associatedtype To

    var cacheKey: String { get }
    var from: From { get }

    func fetch(for models: [From]) async throws -> [To]
}

extension EagerLoadable {
    public var cacheKey: String {
        "\(Self.self)"
    }

    @discardableResult
    public func eagerLoad(on models: [From]) async throws -> [To] {
        let key = cacheKey
        let values = try await fetch(for: models)
        for (model, results) in zip(models, values) {
            model.cache(key: key, value: results)
        }

        return values
    }

    public func get() async throws -> To {
        guard let cached = try from.checkCache(key: cacheKey, To.self) else {
            return try await eagerLoad(on: [from])[0]
        }

        return cached
    }

    public func callAsFunction() async throws -> To {
        try await get()
    }
}

extension Query {
    public func with<E: EagerLoadable>(_ loader: @escaping (Result) -> E) -> Self where E.From == Result {
        didLoad { models in
            guard let first = models.first else {
                return
            }

            try await loader(first).eagerLoad(on: models)
        }
    }
}
