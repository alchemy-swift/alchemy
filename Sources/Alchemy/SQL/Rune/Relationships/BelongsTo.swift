extension Model {
    public typealias BelongsTo<To: ModelOrOptional> = BelongsToRelation<Self, To>

    public func belongsTo<To: ModelOrOptional>(db: Database = DB,
                                               _ type: To.Type = To.self,
                                               from fromKey: String? = nil,
                                               to toKey: String? = nil) -> BelongsTo<To> {
        BelongsTo(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public struct BelongsToRelation<From: Model, To: ModelOrOptional>: Relation {
    let db: Database
    let toKey: String
    let _fromKey: String?
    var fromKey: String {
        _fromKey ?? To.M.referenceKey
    }

    public let from: From
    public var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    fileprivate init(db: Database, from: From, fromKey: String?, toKey: String?) {
        self.db = db
        self.from = from
        self._fromKey = fromKey
        self.toKey = toKey ?? To.M.idKey
    }

    public func fetch(for models: [From]) async throws -> [To] {
        let ids = models.map(\.row[fromKey])
        let rows = try await To.M.query(db: db).where(toKey, in: ids).select()
        let rowsByToColumn = rows.grouped(by: \.[toKey])
        return try ids
            .map { rowsByToColumn[$0] ?? [] }
            .map { try $0.mapDecode(To.M.self) }
            .map { try To(models: $0) }
    }
}
