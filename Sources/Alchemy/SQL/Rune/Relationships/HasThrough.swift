extension Model {
    public typealias HasOneThrough<To: ModelOrOptional> = HasThroughRelation<Self, To>
    public typealias HasManyThrough<To: Model> = HasThroughRelation<Self, [To]>
}

extension HasRelation where To: ModelOrOptional {
    public func through(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> From.HasOneThrough<To> {
        HasThroughRelation(db: db, from: self.from, fromKey: self.fromKey, toKey: self._toKey)
            .through(table, from: fromKey, to: toKey)
    }
}

extension HasRelation where To: Sequence {
    public func through(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> From.HasManyThrough<To.M> {
        HasThroughRelation(db: db, from: self.from, fromKey: self.fromKey, toKey: self._toKey)
            .through(table, from: fromKey, to: toKey)
    }
}

public final class HasThroughRelation<From: Model, To: OneOrMany>: Relation {
    let db: Database
    let fromKey: String
    var _toKey: String?
    var toKey: String {
        _toKey ?? throughs.first?.from ?? Table.model(From.self).referenceKey(mapping: db.keyMapping)
    }

    private var throughs: [Through] = []

    public let from: From
    public var cacheKey: String {
        "\(name(of: Self.self))_\(fromKey)_\(toKey)"
    }

    fileprivate init(db: Database, from: From, fromKey: String?, toKey: String?) {
        self.db = db
        self.from = from
        self.fromKey = fromKey ?? From.idKey
        self._toKey = toKey
        self.throughs = []
    }

    public func fetch(for models: [From]) async throws -> [To] {
        var query: Query<To.M> = To.M.query(db: db)
        for join in calculateJoins() {
            query = query.join(join)
        }

        let toTable = Table.model(To.M.self).string
        let lookupTable = throughs.first?.table.string ?? toTable
        let lookupColumn = throughs.first?.from ?? toKey

        let ids = models.map(\.row[fromKey])
        let lookupKey = "\(lookupTable).\(lookupColumn)"
        let lookupAlias = "__lookup"
        let columns: [String]? = ["\(toTable).*", "\(lookupKey) as \(lookupAlias)"]
        let rows = try await query.where(lookupKey, in: ids).select(columns)
        let rowsByToColumn = rows.grouped(by: \.[lookupAlias])
        return try ids.map { rowsByToColumn[$0] ?? [] }
            .map { try $0.mapDecode(To.M.self) }
            .map { try To(models: $0) }
    }

    // These need to be calculated at run time if we want to allow the builder
    // to add multiple `through`s. This is because each through needs to look
    // back at the previous one to infer which keys to use.
    //
    // Is there a way to isolate the key mapping and inference logic to either the functions themselves or elsewhere?
    private func calculateJoins() -> [SQLJoin] {
        var nextTable: Table = .model(To.M.self)
        var previousTable = throughs.last?.table ?? .model(To.M.self)
        var nextKey: String = _toKey ?? previousTable.referenceKey(mapping: db.keyMapping)

        var joins: [SQLJoin] = []
        for (index, through) in throughs.reversed().enumerated() {
            let toKey: String = through.to ?? through.table.idKey(mapping: db.keyMapping)
            let join = SQLJoin(type: .inner, joinTable: through.table.string)
                .on(first: "\(through.table.string).\(toKey)", op: .equals, second: "\(nextTable.string).\(nextKey)")
            joins.append(join)

            nextTable = through.table
            previousTable = throughs[safe: index - 1]?.table ?? .model(From.self)
            nextKey = through.from ?? nextTable.referenceKey(mapping: db.keyMapping)
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

private struct Through {
    let table: Table
    let from: String?
    let to: String?
}

private enum Table {
    case model(any Model.Type)
    case string(String)

    func idKey(mapping: KeyMapping) -> String {
        switch self {
        case .model(let model):
            return model.idKey
        case .string:
            return mapping.encode("Id")
        }
    }

    func referenceKey(mapping: KeyMapping) -> String {
        switch self {
        case .model(let model):
            return model.referenceKey
        case .string(let string):
            return mapping.encode(string.singularized + "Id")
        }
    }

    var string: String {
        switch self {
        case .model(let model):
            return model.tableName
        case .string(let string):
            return string
        }
    }
}
