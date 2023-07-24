/*
 This has
 1. an initial relationship
 2. a result type.
 2. a key path from the initial relationship to the result type.
 3. something to be applied on the initial relationship query?
 */

/*
 ISSUES
 1. if there's an array along the chain, should make every subsequent To and arrary.
 2. not caching intermediaries properly.
 */

@dynamicMemberLookup
public struct CompoundRelationship<From: Model, Through: OneOrMany, To: OneOrMany, A: EagerLoadable, B: EagerLoadable>: EagerLoadable
    where A.From == From, A.To == Through, B.From == Through.M, B.To == To
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
        let middle = try await loader.fetch(for: models)

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
                flattened.append(values)
            }

            let newTo = try To(models: flattened.flatMap { $0.toArray() })
            results.append(newTo)
        }

        return results
    }
}

extension CompoundRelationship where To: Sequence {
    public subscript<C: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, C>) -> CompoundRelationship<From, To, C.To, Self, C>
        where C.To: ModelOrOptional
    {
        // TODO: Enforce that To will be array, even though C.To is not.
        CompoundRelationship<From, To, C.To, Self, C>(from: from, loader: self, next: relationship)
    }

    public subscript<C: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, C>) -> CompoundRelationship<From, To, C.To, Self, C>
        where C.To: Sequence
    {
        CompoundRelationship<From, To, C.To, Self, C>(from: from, loader: self, next: relationship)
    }
}

extension CompoundRelationship where To: ModelOrOptional {
    public subscript<C: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, C>) -> CompoundRelationship<From, To, C.To, Self, C> {
        CompoundRelationship<From, To, C.To, Self, C>(from: from, loader: self, next: relationship)
    }
}

extension Relation {
    public subscript<E: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, E>) -> CompoundRelationship<From, To, E.To, Relation<From, To>, E> {
        CompoundRelationship(from: from, loader: self, next: relationship)
    }
}
