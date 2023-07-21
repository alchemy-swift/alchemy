extension Model {
    public typealias HasMany<To: Model> = HasManyRelation<Self, To>

    public func hasMany<To: Model>(
        db: Database = DB,
        _ type: To.Type = To.self,
        from fromKey: String? = nil,
        to toKey: String? = nil
    ) -> HasMany<To> {
        HasMany(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public struct HasManyRelation<From: Model, M: Model>: Relation {
    let db: Database
    let fromKey: String
    let _toKey: String?
    var toKey: String {
        _toKey ?? From.referenceKey
    }

    public let from: From
    public var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    fileprivate init(db: Database, from: From, fromKey: String?, toKey: String?) {
        self.db = db
        self.from = from
        self.fromKey = fromKey ?? From.idKey
        self._toKey = toKey
    }

    public func fetch(for models: [From]) async throws -> [[M]] {
        let ids = models.map(\.row[fromKey])
        let rows = try await To.Element.query(db: db).where(toKey, in: ids).select()
        let rowsByToColumn = rows.grouped(by: \.[toKey])
        return try ids
            .map { rowsByToColumn[$0] ?? [] }
            .map { try $0.mapDecode(M.self) }
    }
}
