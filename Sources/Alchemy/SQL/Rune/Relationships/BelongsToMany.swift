extension Model {
    public typealias BelongsToMany<To: ModelOrOptional> = BelongsToManyRelation<Self, To>

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

public struct BelongsToManyRelation<From: Model, To: ModelOrOptional>: Relation {
    let db: Database
    public let from: From

    let fromKey: String
    let toKey: String
    let pivot: String
    let pivotFrom: String
    let pivotTo: String

    public var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)_\(pivot)_\(pivotFrom)_\(pivotTo)"
    }

    init(db: Database, from: From, fromKey: String?, toKey: String?, pivot: String?, pivotFrom: String?, pivotTo: String?) {
        self.db = db
        self.from = from
        self.fromKey = fromKey ?? From.idKey
        self.toKey = toKey ?? To.M.idKey
        self.pivot = pivot ?? From.tableName.singularized + "_" + To.M.tableName.singularized
        self.pivotFrom = pivotFrom ?? From.referenceKey
        self.pivotTo = pivotTo ?? To.M.referenceKey
    }

    public func fetch(for models: [From]) async throws -> [To] {
        let ids = models.map(\.row[fromKey])
        let rows = try await To.M.query(db: db).where(toKey, in: ids).select()
        let rowsByToColumn = rows.grouped(by: \.[toKey])
        return try ids
            .map { rowsByToColumn[$0] ?? [] }
            .map { try $0.first?.decode(To.M.self) }
            .map { try To(model: $0) }
    }
}
