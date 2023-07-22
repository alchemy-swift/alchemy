extension Model {
    public typealias HasOne<To: ModelOrOptional> = HasRelation<Self, To>
    public typealias HasMany<To: Model> = HasRelation<Self, [To]>

    public func hasMany<To: Model>(db: Database = DB,
                                   _ type: To.Type = To.self,
                                   from fromKey: String? = nil,
                                   to toKey: String? = nil) -> HasMany<To> {
        HasMany(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }

    public func hasOne<To: ModelOrOptional>(db: Database = DB,
                                            _ type: To.Type = To.self,
                                            from fromKey: String? = nil,
                                            to toKey: String? = nil) -> HasOne<To> {
        HasOne(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public final class HasRelation<From: Model, To: OneOrMany>: Relation<From, To> {
    let fromKey: String
    let _toKey: String?
    var toKey: String {
        _toKey ?? From.referenceKey
    }

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    fileprivate init(db: Database, from: From, fromKey: String?, toKey: String?) {
        self.fromKey = fromKey ?? From.idKey
        self._toKey = toKey
        super.init(db: db, from: from)
    }

    public override func fetch(for models: [From]) async throws -> [To] {
        let ids = models.map(\.row[fromKey])
        let results = try await `where`(toKey, in: ids).get(nil)
        let resultsByToColumn = results.grouped(by: \.row[toKey])
        return try ids
            .map { resultsByToColumn[$0] ?? [] }
            .map { try To(models: $0) }
    }
}
