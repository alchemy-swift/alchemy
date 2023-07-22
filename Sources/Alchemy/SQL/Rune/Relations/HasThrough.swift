extension Model {
    public typealias HasOneThrough<To: ModelOrOptional> = HasThroughRelation<Self, To>
    public typealias HasManyThrough<To: Model> = HasThroughRelation<Self, [To]>
}

extension HasRelation where To: ModelOrOptional {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasOneThrough<To> {
        HasThroughRelation(db: db, from: from, fromKey: fromKey, toKey: toKey)
            .through(table, from: throughFromKey, to: throughToKey)
    }
}

extension HasRelation where To: Sequence {
    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> From.HasManyThrough<To.M> {
        HasThroughRelation(db: db, from: from, fromKey: fromKey, toKey: toKey)
            .through(table, from: throughFromKey, to: throughToKey)
    }
}

public final class HasThroughRelation<From: Model, To: OneOrMany>: Relation<From, To> {
    var throughs: [Through] = []

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    public override func fetch(for models: [From]) async throws -> [To] {
        setJoins()
        let lookupKey = "\(throughs.first!.table).\(throughs.first!.from)"
        let columns = ["\(table).*", lookupKey]
        let ids = models.map(\.row[fromKey.string])
        let results = try await `where`(lookupKey, in: ids).get(columns)
        let resultsByLookup = results.grouped(by: \.row[lookupKey])
        return try ids.map { try To(models: resultsByLookup[$0] ?? []) }
    }

    private func setJoins() {
        var nextKey = "\(table).\(toKey)"
        for through in throughs.reversed() {
            join(table: through.table, first: "\(through.table).\(through.to)", second: nextKey)
            nextKey = "\(through.table).\(through.from)"
        }
    }

    public func through(_ table: String, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: OR throughs.last.table.referenceKey if another through exists!
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(db.keyMapping.encode("Id")).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        throughs.append(Through(table: table, from: from, to: to))
        return self
    }

    public func through(_ model: (some Model).Type, from throughFromKey: String? = nil, to throughToKey: String? = nil) -> Self {
        // TODO: OR throughs.last.table.referenceKey if another through exists!
        let from: SQLKey = .infer(From.referenceKey).specify(throughFromKey)
        let to: SQLKey = .infer(model.idKey).specify(throughToKey)
        toKey = toKey.infer(db.keyMapping.encode(table.singularized + "Id"))
        throughs.append(Through(table: model.table, from: from, to: to))
        return self
    }
}
