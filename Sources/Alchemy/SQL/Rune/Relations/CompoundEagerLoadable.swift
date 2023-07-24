private struct CompoundRelation<From: Model, Through: OneOrMany, To: OneOrMany, A: EagerLoadable, B: EagerLoadable>: EagerLoadable
    where A.From == From, A.To == Through, B.To: OneOrMany, B.From == Through.M, B.To.M == To.M
{
    public var from: From
    public var loader: A
    public var next: KeyPath<Through.M, B>

    init(from: From, loader: A, next: KeyPath<Through.M, B>) {
        self.from = from
        self.loader = loader
        self.next = next
    }

    public func fetch(for models: [From]) async throws -> [To] {
        // 1. Load first results.
        let middle = try await loader.eagerLoad(on: models)

        // 2. Eager load next on first results.
        guard let first = middle.first?.toArray().first else {
            return []
        }

        let middleFlattened = middle.flatMap { $0.toArray() }
        try await first[keyPath: next].eagerLoad(on: middleFlattened)

        // 3. Return all next results.
        var results: [To] = []
        for m in middle {
            var flattened: [To] = []
            for model in m.toArray() {
                let values = try await model[keyPath: next].get()
                let to = try To(models: values.toArray())
                flattened.append(to)
            }

            let newTo = try To(models: flattened.flatMap { $0.toArray() })
            results.append(newTo)
        }

        return results
    }
}

extension EagerLoadable where To: Sequence & OneOrMany {
    public subscript<T: OneOrMany, C: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, C>) -> some EagerLoadable<From, [T.M]>
        where C.To == T, To.M == C.From
    {
        CompoundRelation<From, To, [T.M], Self, C>(from: from, loader: self, next: relationship)
    }
}

extension EagerLoadable where To: ModelOrOptional {
    public subscript<C: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, C>) -> some EagerLoadable<From, C.To>
        where C.To: OneOrMany, To.M == C.From
    {
        CompoundRelation<From, To, C.To, Self, C>(from: from, loader: self, next: relationship)
    }
}
