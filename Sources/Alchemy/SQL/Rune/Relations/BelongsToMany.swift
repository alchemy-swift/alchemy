extension Model {
    public typealias BelongsToMany<To: Model> = BelongsToManyRelation<Self, To>

    public func belongsToMany<To: ModelOrOptional>(db: Database = DB,
                                                   _ type: To.Type = To.self,
                                                   from fromKey: String? = nil,
                                                   to toKey: String? = nil,
                                                   pivot: String? = nil,
                                                   pivotFrom: String? = nil,
                                                   pivotTo: String? = nil) -> BelongsToMany<To> {
        let from: SQLKey = .infer(Self.idKey).specify(fromKey)
        let to: SQLKey = .infer(To.idKey).specify(toKey)
        let pivot: String = pivot ?? Self.table.singularized + "_" + M.table.singularized
        let pivotFrom: SQLKey = .infer(Self.referenceKey).specify(pivotFrom)
        let pivotTo: SQLKey = .infer(To.referenceKey).specify(pivotTo)
        return BelongsToMany(db: db, from: self, fromKey: from, toKey: to, pivot: pivot, pivotFrom: pivotFrom, pivotTo: pivotTo)
    }
}

public class BelongsToManyRelation<From: Model, M: Model>: Relation<From, [M]> {
    let pivot: String
    let pivotFrom: SQLKey
    let pivotTo: SQLKey

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)_\(pivot)_\(pivotFrom)_\(pivotTo)"
    }

    init(db: Database, from: From, fromKey: SQLKey, toKey: SQLKey, pivot: String, pivotFrom: SQLKey, pivotTo: SQLKey) {
        self.pivot = pivot
        self.pivotFrom = pivotFrom
        self.pivotTo = pivotTo
        super.init(db: db, from: from, fromKey: fromKey, toKey: toKey)
    }

    public override func fetch(for models: [From]) async throws -> [[M]] {
        join(table: pivot, first: "\(pivot).\(pivotTo)", second: "\(M.table).\(toKey.string)")
        let ids = models.map(\.row[fromKey.string])
        let results = try await `where`("\(pivot).\(pivotFrom)", in: ids).get(nil)
        let resultsByToColumn = results.grouped(by: \.row[toKey.string])
        return try ids
            .map { resultsByToColumn[$0] ?? [] }
            .map { try [M](models: $0) }
    }
}
