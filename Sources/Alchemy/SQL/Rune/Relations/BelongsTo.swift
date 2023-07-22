extension Model {
    public typealias BelongsTo<To: ModelOrOptional> = BelongsToRelation<Self, To>

    public func belongsTo<To: ModelOrOptional>(db: Database = DB,
                                               _ type: To.Type = To.self,
                                               from fromKey: String? = nil,
                                               to toKey: String? = nil) -> BelongsTo<To> {
        let from: SQLKey = .infer(To.M.referenceKey).specify(fromKey)
        let to: SQLKey = .infer(To.M.idKey).specify(toKey)
        return BelongsTo(db: db, from: self, fromKey: from, toKey: to)
    }
}

public class BelongsToRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
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
