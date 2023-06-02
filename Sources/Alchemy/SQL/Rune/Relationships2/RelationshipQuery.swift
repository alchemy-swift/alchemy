/// One of these per eager loadable relationship.
public final class ModelRelationship<From: Model, To: RelationAllowed> {
    let from: From
    let query: RelationshipQuery

    init(from: From, query: RelationshipQuery) {
        self.from = from
        self.query = query
    }

    func eagerLoad(on input: [From]) async throws {
        let inputRows = input.map(\.row)
        let rows = try await query.execute(input: inputRows)
        let values = try rows
            .map { try $0.mapDecode(To.M.self) }
            .map { try To(models: $0) }
        for (model, results) in zip(input, values) {
            model.cache(hashValue: query.hashValue, value: results)
        }
    }

    public func get() async throws -> To {
        guard let value: To = try from.checkCache(hashValue: query.hashValue) else {
            let results = try await query.execute(input: [from.row])[0]
            let models = try results.mapDecode(To.M.self)
            let value = try To(models: models)
            from.cache(hashValue: query.hashValue, value: value)
            return value
        }

        return value
    }

    public func callAsFunction() async throws -> To {
        try await get()
    }
}

struct Key: Hashable {
    struct Table: Hashable {
        let string: String
        let idKey: String
        let referenceKey: String

        static func model(_ model: (some Model).Type) -> Table {
            Table(string: model.tableName, idKey: model.idKey, referenceKey: model.referenceKey)
        }

        static func string(_ string: String, keyMapping: DatabaseKeyMapping) -> Table {
            let id = keyMapping.map(input: "Id")
            let ref = keyMapping.map(input: string.singularized + "Id")
            return Table(string: string, idKey: id, referenceKey: ref)
        }
    }

    let table: Table
    let column: String?
}

/// Describes a relationship between SQL tables. A single query.
final class RelationshipQuery: Hashable {
    /// Used to infer default keys.
    enum Kind {
        case has
        case belongs
    }

    private struct Through {
        // Ensure key mapping is used to find defaults.
        let table: Key.Table
        let from: String?
        let to: String?
        let isPivot: Bool
    }

    private let db: Database
    private let type: Kind
    private let from: Key
    private let to: Key
    private var throughs: [Through] = []
    private var wheres: [SQLWhere] = []

    init(db: Database, type: Kind, from: Key, to: Key) {
        self.db = db
        self.type = type
        self.from = from
        self.to = to
    }

    func calculateJoins() -> [SQLJoin] {
        var nextTable = to.table
        var previousTable = throughs.last?.table ?? from.table
        var nextKey: String = to.column ?? {
            switch type {
            case .belongs:
                return nextTable.idKey
            case .has:
                return previousTable.referenceKey
            }
        }()

        // TODO: Check for Pivot for default keys

        var joins: [SQLJoin] = []
        for (index, through) in throughs.reversed().enumerated() {
            var toKey: String = through.to ?? {
                switch type {
                case .belongs:
                    return nextTable.referenceKey
                case .has:
                    return through.table.idKey
                }
            }()

            let join = SQLJoin(type: .inner, joinTable: through.table.string)
                .on(first: "\(through.table.string).\(toKey)", op: .equals, second: "\(nextTable.string).\(nextKey)")
            joins.append(join)

            nextTable = through.table
            previousTable = throughs[safe: index - 1]?.table ?? from.table

            nextKey = through.from ?? {
                switch type {
                case .belongs:
                    return previousTable.idKey
                case .has:
                    return nextTable.referenceKey
                }
            }()
        }

        return joins
    }

    func addThrough(_ table: String, from: String? = nil, to: String? = nil, isPivot: Bool = false) {
        throughs.append(Through(table: .string(table, keyMapping: .convertToSnakeCase), from: from, to: to, isPivot: isPivot))
    }

    func addWhere(_ where: SQLWhere) {
        wheres.append(`where`)
    }

    /// Execute the relationship given the input rows. Always returns an array
    /// the same length as the input array.
    func execute(input: [SQLRow]) async throws -> [[SQLRow]] {
        var query = db.from(to.table.string)

        for join in calculateJoins() {
            query = query.join(join)
        }

        for `where` in wheres {
            query = query.where(`where`)
        }

        let thisTable = from.table
        let nextTable = throughs.first?.table ?? to.table
        let fromColumn: String = from.column ?? {
            switch type {
            case .belongs:
                return thisTable.referenceKey
            case .has:
                return nextTable.idKey
            }
        }()

        let toTable = throughs.first?.table.string ?? to.table.string
        let toColumn: String = throughs.first?.from ?? to.column ?? {
            switch type {
            case .belongs:
                return nextTable.idKey
            case .has:
                return thisTable.referenceKey
            }
        }()

        var lookupKey = toColumn
        var lookupAlias = lookupKey

        var columns: [String] = ["\(to.table.string).*"]
        if let first = throughs.first {
            lookupKey = "\(toTable).\(toColumn)"
            lookupAlias = "__lookup"
            columns.append("\(lookupKey) as \(lookupAlias)")
        }

        let inputValues = try input.map { try $0.require(fromColumn) }
        let results: [SQLRow] = try await query
            .where("\(lookupKey)", in: inputValues)
            .select(columns)

        let resultsByToColumn = results.grouped(by: \.[lookupAlias])
        return inputValues.map { resultsByToColumn[$0] ?? [] }
    }

    // MARK: - Hashable

    public static func == (lhs: RelationshipQuery, rhs: RelationshipQuery) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(from)
        hasher.combine(to)
    }
}

extension Query where Result: Model {
    public func with<T: RelationAllowed>(
        _ relationship: @escaping (Result) -> Result.Relationship<T>,
        nested: @escaping ((Result.Relationship<T>) -> Result.Relationship<T>) = { $0 }
    ) -> Self {
        didLoad { models in
            guard let first = models.first else {
                return
            }

            let query = nested(relationship(first))
            try await query.eagerLoad(on: models)
        }
    }
}

extension ModelRelationship {
    fileprivate static func has(db: Database, _ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Key(table: .model(From.self), column: from)
        let toKey = Key(table: .model(To.M.self), column: to)
        let query = RelationshipQuery(db: db, type: .has, from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }

    fileprivate static func belongs(db: Database, _ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Key(table: .model(From.self), column: from)
        let toKey = Key(table: .model(To.M.self), column: to)
        let query = RelationshipQuery(db: db, type: .belongs, from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }
}

// MARK: - Default Relationships

extension Model {
    public typealias Relationship<To: RelationAllowed> = ModelRelationship<Self, To>

    public func hasMany<To: Model>(db: Database = DB, _ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<[To]> {
        return .has(db: db, self, from: fromKey, to: toKey)
    }

    public func hasOne<To: Model>(db: Database = DB, _ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To> {
        return .has(db: db, self, from: fromKey, to: toKey)
    }

    public func hasOne<To: Model>(db: Database = DB, _ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To?> {
        return .has(db: db, self, from: fromKey, to: toKey)
    }

    public func belongsTo<To: Model>(db: Database = DB, _ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To> {
        return .belongs(db: db, self, from: fromKey, to: toKey)
    }

    public func belongsTo<To: Model>(db: Database = DB, _ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship<To?> {
        return .belongs(db: db, self, from: fromKey, to: toKey)
    }
}

// MARK: - Relationship Modifiers

extension ModelRelationship {

    public func through(_ table: String, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        query.addThrough(table, from: from, to: to)
        return self
    }

    public func throughPivot(_ table: String, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        query.addThrough(table, from: from, to: to, isPivot: true)
        return self
    }

    public func `where`(_ where: SQLWhere) {
        query.addWhere(`where`)
    }

    public subscript<T: RelationAllowed>(dynamicMember relationship: KeyPath<To.M, To.M.Relationship<T>>) -> From.Relationship<T> {
        // Could add a through, however it would be great to eager load the intermidiary relationship.
        fatalError()
    }
}
