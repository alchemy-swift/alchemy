public protocol EagerLoadable {
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

    public func eagerLoad(on models: [From]) async throws {
        let key = cacheKey
        let values = try await fetch(for: models)
        for (model, results) in zip(models, values) {
            model.cache(key: key, value: results)
        }
    }

    public func get() async throws -> To {
        let key = cacheKey
        if let cached = try from.checkCache(key: key, To.self) {
            return cached
        }

        let value = try await fetch(for: [from])[0]
        from.cache(key: key, value: value)
        return value
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
