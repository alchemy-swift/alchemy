private struct CompoundRelation<From: Model, To: OneOrMany, A: EagerLoadable, B: EagerLoadable>: EagerLoadable
    where A.To: OneOrMany, B.To: OneOrMany, A.From == From, B.From == A.To.M, B.To.M == To.M
{
    var from: From
    var relationA: A
    var relationBKey: KeyPath<A.To.M, B>

    init(from: From, relationA: A, relationBKey: KeyPath<A.To.M, B>) {
        self.from = from
        self.relationA = relationA
        self.relationBKey = relationBKey
    }

    func fetch(for models: [From]) async throws -> [To] {
        
        // 1. Eager load relation a.
        
        let aResults = try await relationA.load(on: models)
        let aModels = aResults.flatMap(\.array)

        // 2. Eager load relation b.
        
        try await aModels.first?[keyPath: relationBKey].load(on: aModels)

        // 3. Return the results of relation b.
        
        return try aResults
            .map(\.array)
            .map { try $0.flatMap { try $0[keyPath: relationBKey].require().array }}
            .map { try To(models: $0) }
    }
}

extension EagerLoadable where To: ModelOrOptional {
    public subscript<C: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, C>) -> some EagerLoadable<From, C.To>
        where C.To: OneOrMany, To.M == C.From
    {
        CompoundRelation<From, C.To, Self, C>(from: from, relationA: self, relationBKey: relationship)
    }
}

extension EagerLoadable where To: Sequence & OneOrMany {
    public subscript<T: OneOrMany, C: EagerLoadable>(dynamicMember relationship: KeyPath<To.M, C>) -> some EagerLoadable<From, [T.M]>
        where C.To == T, To.M == C.From
    {
        CompoundRelation<From, [T.M], Self, C>(from: from, relationA: self, relationBKey: relationship)
    }
}
