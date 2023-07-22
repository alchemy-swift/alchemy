extension Model {
    public typealias HasOne<To: ModelOrOptional> = HasRelation<Self, To>
    public typealias HasMany<To: Model> = HasRelation<Self, [To]>

    public func hasMany<To: Model>(db: Database = DB,
                                   _ type: To.Type = To.self,
                                   from fromKey: String? = nil,
                                   to toKey: String? = nil) -> HasMany<To> {
        let from: SQLKey = .infer(Self.idKey).specify(fromKey)
        let to: SQLKey = .infer(Self.referenceKey).specify(toKey)
        return HasMany(db: db, from: self, fromKey: from, toKey: to)
    }

    public func hasOne<To: ModelOrOptional>(db: Database = DB,
                                            _ type: To.Type = To.self,
                                            from fromKey: String? = nil,
                                            to toKey: String? = nil) -> HasOne<To> {
        let from: SQLKey = .infer(Self.idKey).specify(fromKey)
        let to: SQLKey = .infer(Self.referenceKey).specify(toKey)
        return HasOne(db: db, from: self, fromKey: from, toKey: to)
    }
}

public final class HasRelation<From: Model, To: OneOrMany>: Relation<From, To> {
    let fromKey: SQLKey
    let toKey: SQLKey

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    fileprivate init(db: Database, from: From, fromKey: SQLKey, toKey: SQLKey) {
        self.fromKey = fromKey
        self.toKey = toKey
        super.init(db: db, from: from)
    }

    public override func fetch(for models: [From]) async throws -> [To] {
        let ids = models.map(\.row[fromKey.string])
        let results = try await `where`(toKey.string, in: ids).get(nil)
        let resultsByToColumn = results.grouped(by: \.row[toKey.string])
        return try ids
            .map { resultsByToColumn[$0] ?? [] }
            .map { try To(models: $0) }
    }
}
