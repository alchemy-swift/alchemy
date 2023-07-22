extension Model {
    public typealias BelongsToThrough<To: ModelOrOptional> = BelongsToThroughRelation<Self, To>
}

extension BelongsToRelation {
    public func through(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> From.BelongsToThrough<To> {
        let from: SQLKey = self.fromKey.infer(Table.string(table).referenceKey(mapping: db.keyMapping))
        let to: SQLKey = self.toKey
        return BelongsToThroughRelation(db: db, from: self.from, fromKey: from, toKey: to)
            .through(table, from: fromKey, to: toKey)
    }
}

public final class BelongsToThroughRelation<From: Model, To: ModelOrOptional>: Relation<From, To> {
    let toKey: SQLKey
    let fromKey: SQLKey

    private var throughs: [Through] = []

    public override var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    fileprivate init(db: Database, from: From, fromKey: SQLKey, toKey: SQLKey) {
        self.fromKey = fromKey
        self.toKey = toKey
        self.throughs = []
        super.init(db: db, from: from)
    }

    public override func fetch(for models: [From]) async throws -> [To] {
        for j in calculateJoins() {
            join(j)
        }

        let toTable = Table.model(To.M.self).string
        let lookupTable = throughs.first?.table.string ?? toTable
        let lookupColumn = throughs.first?.from ?? toKey.string

        let lookupKey = "\(lookupTable).\(lookupColumn)"
        let lookupAlias = "__lookup"
        let columns: [String]? = ["\(toTable).*", "\(lookupKey) AS \(lookupAlias)"]
        let ids = models.map(\.row[fromKey.string])
        let results = try await `where`(lookupKey, in: ids).get(columns)
        let resultsByLookup = results.grouped(by: \.row[lookupAlias])
        return try ids
            .map { resultsByLookup[$0] ?? [] }
            .map { try To(models: $0) }
    }

    // These need to be calculated at run time if we want to allow the builder
    // to add multiple `through`s. This is because each through needs to look
    // back at the previous one to infer which keys to use.
    //
    // Is there a way to isolate the key mapping and inference logic to either the functions themselves or elsewhere?
    private func calculateJoins() -> [SQLJoin] {
        var nextTable: Table = .model(To.M.self)
        var nextKey: String = toKey.string

        var joins: [SQLJoin] = []
        for through in throughs.reversed() {
            let toKey: String = through.to ?? nextTable.referenceKey(mapping: db.keyMapping)
            let join = SQLJoin(type: .inner, joinTable: through.table.string)
                .on(first: "\(through.table.string).\(toKey)", op: .equals, second: "\(nextTable.string).\(nextKey)")
            joins.append(join)

            nextTable = through.table
            nextKey = through.from ?? nextTable.idKey(mapping: db.keyMapping)
        }

        return joins
    }

    public func through(_ table: String, from: String? = nil, to: String? = nil) -> Self {
        throughs.append(Through(table: .string(table), from: from, to: to))
        return self
    }

    public func through(_ model: (some Model).Type, from: String? = nil, to: String? = nil) -> Self {
        throughs.append(Through(table: .model(model), from: from, to: to))
        return self
    }
}
