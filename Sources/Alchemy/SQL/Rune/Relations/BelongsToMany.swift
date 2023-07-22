extension Model {
    public typealias BelongsToMany<To: Model> = BelongsToManyRelation<Self, To>

    public func belongsToMany<To: ModelOrOptional>(db: Database = DB,
                                                   _ type: To.Type = To.self,
                                                   from fromKey: String? = nil,
                                                   to toKey: String? = nil,
                                                   pivot: String? = nil,
                                                   pivotFrom: String? = nil,
                                                   pivotTo: String? = nil) -> BelongsToMany<To> {
        BelongsToMany(db: db, from: self, fromKey: fromKey, toKey: toKey, pivot: pivot, pivotFrom: pivotFrom, pivotTo: pivotTo)
    }
}

public class BelongsToManyRelation<From: Model, M: Model>: Relation<From, [M]> {
    let fromKey: String
    let toKey: String
    let pivot: String
    let pivotFrom: String
    let pivotTo: String

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)_\(pivot)_\(pivotFrom)_\(pivotTo)"
    }

    init(db: Database, from: From, fromKey: String?, toKey: String?, pivot: String?, pivotFrom: String?, pivotTo: String?) {
        self.fromKey = fromKey ?? From.idKey
        self.toKey = toKey ?? M.idKey
        self.pivot = pivot ?? From.table.singularized + "_" + M.table.singularized
        self.pivotFrom = pivotFrom ?? From.referenceKey
        self.pivotTo = pivotTo ?? M.referenceKey
        super.init(db: db, from: from)
    }

    public override func fetch(for models: [From]) async throws -> [[M]] {
        join(table: pivot, first: "\(pivot).\(pivotTo)", second: "\(M.table).\(toKey)")
        let ids = models.map(\.row[fromKey])
        let results = try await `where`("\(pivot).\(pivotFrom)", in: ids).get(nil)
        let resultsByToColumn = results.grouped(by: \.row[toKey])
        return try ids
            .map { resultsByToColumn[$0] ?? [] }
            .map { try [M](models: $0) }
    }
}
