@dynamicMemberLookup
public protocol EagerLoadable<From, To> {
    associatedtype From: Model
    associatedtype To

    /// The model instance this relation was accessed from.
    var from: From { get }
    var cacheKey: String { get }

    /// Load results given the input rows. Results must be the same length and
    /// order as the input.
    func fetch(for models: [From]) async throws -> [To]
}

extension EagerLoadable {
    public var cacheKey: String {
        "\(Self.self)"
    }

    public var isLoaded: Bool {
        from.cacheExists(cacheKey)
    }

    @discardableResult
    public func load(on models: [From]) async throws -> [To] {
        let key = cacheKey
        let values = try await fetch(for: models)
        for (model, results) in zip(models, values) {
            model.cache(results, at: key)
        }

        return values
    }

    public func value() async throws -> To {
        guard let cached = try from.cached(at: cacheKey, To.self) else {
            return try await load()
        }

        return cached
    }

    public func load() async throws -> To {
        try await load(on: [from])[0]
    }

    public func require() throws -> To {
        guard let cached = try from.cached(at: cacheKey, To.self) else {
            throw RuneError("\(Self.To.self) wasn't eager loaded and must be fetched.")
        }

        return cached
    }

    public func force() -> To {
        do {
            guard let cached = try from.cached(at: cacheKey, To.self) else {
                preconditionFailure("\(Self.To.self) wasn't eager loaded and must be fetched.")
            }

            return cached
        }
        catch {
            preconditionFailure("Error forcing relationship: \(error).")
        }
    }

    public func callAsFunction() async throws -> To {
        try await value()
    }
}

extension Query {
    public func with<E: EagerLoadable>(_ loader: @escaping (Result) -> E) -> Self where E.From == Result {
        didLoad { models in
            guard let first = models.first else { return }
            try await loader(first).load(on: models)
        }
    }
}

extension Array where Element: Model {
    public func load<E: EagerLoadable>(_ loader: @escaping (Element) -> E) async throws where E.From == Element {
        guard let first else { return }
        try await loader(first).load(on: self)
    }

    public func with<E: EagerLoadable>(_ loader: @escaping (Element) -> E) async throws -> Self where E.From == Element {
        guard let first else { return self }
        try await loader(first).load(on: self)
        return self
    }
}
