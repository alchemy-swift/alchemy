extension Model {
    public typealias BelongsTo<To: ModelOrOptional> = BelongsToRelation<Self, To>

    public func belongsTo<To: ModelOrOptional>(db: Database = DB,
                                               _ type: To.Type = To.self,
                                               from fromKey: String? = nil,
                                               to toKey: String? = nil) -> BelongsTo<To> {
        BelongsTo(db: db, from: self, fromKey: fromKey, toKey: toKey)
    }
}

public class BelongsToRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    let toKey: String
    let _fromKey: String?
    var fromKey: String {
        _fromKey ?? To.M.referenceKey
    }

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    fileprivate init(db: Database, from: From, fromKey: String?, toKey: String?) {
        self._fromKey = fromKey
        self.toKey = toKey ?? To.M.idKey
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
