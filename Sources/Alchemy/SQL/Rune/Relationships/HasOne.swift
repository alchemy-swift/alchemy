extension Model {
    public typealias HasOne<To: ModelOrOptional> = HasOneRelation<Self, To>

    public func hasOne<To: ModelOrOptional>(
        db: Database = DB,
        _ type: To.Type = To.self,
        from fromKey: String? = nil,
        to toKey: String? = nil
    ) -> HasOne<To> {
        HasOne(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public struct HasOneRelation<From: Model, To: ModelOrOptional>: Relation {
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
