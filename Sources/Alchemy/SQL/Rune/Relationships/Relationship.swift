/*
 Checklist
 1. DONE Add where to Relationship
 2. DONE Add multiple throughs
 3. DONE Infer keys
 4. DONE BelongsTo
 5. DONE HasOne
 6. DONE HasMany
 7. DONE Through pivot
 8. DONE Eager loading
 9. CRUD
 10. Subscript loading
 */

/*
 Refactor to make cleaner.
 - Not clear what logic goes in `ModelRelationship`, `RelationshipQuery`, and `Column`.
 - Not clear how to extend to add custom relationships.
 - Not clear how or where to add CRUD elements.
 - Might be wise to break things down into different types.
 */

/*
 A relationship has:
 1. A query.
 2. A unique set of CRUD ops.
 3. The ability to be eager loaded (run query with arbitrary input ids).
 4. A unique hash value for caching.
 */

/*
 Relationship CRUD:
 1. I'd like to allow custom operations for each relationship type.
 2. However, doing so with type safety will mean exposing the relationship type on the variable. This isn't ideal because it will require duplicate identification as "hasMany" etc.
 3. I could also add functions to all "relationships" and throw an error if it's not supported.
 */

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

    public func through<M: Model>(_ type: M.Type, from: String? = nil, to: String? = nil) -> From.Relationship<To> {
        through(type.tableName, from: from, to: to)
    }

    public func through(_ table: String, from: String? = nil, to: String? = nil) -> From.Relationship<To> {
        // This needs to know if the relationship is has or belongs to infer keys.
        // Therefore the inference needs to be stored in `ModelRelationship`. Can
        // we remove that and just assume stuff here?
        query.addThrough(table, from: from, to: to)
        return self
    }

    public func throughPivot<M: Model>(_ type: M.Type, from: String? = nil, to: String? = nil) -> From.Relationship<To> {
        throughPivot(type.tableName, from: from, to: to)
    }

    public func throughPivot(_ table: String, from: String? = nil, to: String? = nil) -> From.Relationship<To> {
        query.addThrough(table, from: from, to: to, isPivot: true)
        return self
    }

    public func `where`(_ where: SQLWhere) {
        query.addWhere(`where`)
    }

    fileprivate static func has(db: Database, _ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Column(table: .model(From.self), key: from)
        let toKey = Column(table: .model(To.M.self), key: to)
        let query = RelationshipQuery(db: db, type: .has, from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }

    fileprivate static func belongs(db: Database, _ model: From, from: String? = nil, to: String? = nil) -> ModelRelationship<From, To> {
        let fromKey = Column(table: .model(From.self), key: from)
        let toKey = Column(table: .model(To.M.self), key: to)
        let query = RelationshipQuery(db: db, type: .belongs, from: fromKey, to: toKey)
        return ModelRelationship(from: model, query: query)
    }
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
        let table: Column.Table
        let from: String?
        let to: String?
        let isPivot: Bool
    }

    private let db: Database
    private let type: Kind
    private let from: Column
    private let to: Column
    private var throughs: [Through] = []
    private var wheres: [SQLWhere] = []

    init(db: Database, type: Kind, from: Column, to: Column) {
        self.db = db
        self.type = type
        self.from = from
        self.to = to
    }

    // These need to be calculated at run time if we want to allow the builder
    // to add multiple `through`s. This is because each through needs to look
    // back at the previous one to infer which keys to use.
    //
    // Is there a way to isolate the key mapping and inference logic to either the functions themselves or elsewhere?
    func calculateJoins() -> [SQLJoin] {
        var nextTable = to.table
        var previousTable = throughs.last?.table ?? from.table
        var nextKeyImplicit: Bool = to.key == nil
        var nextKey: String = to.key ?? {
            switch type {
            case .belongs:
                return nextTable.idKey
            case .has:
                return previousTable.referenceKey
            }
        }()

        var joins: [SQLJoin] = []
        for (index, through) in throughs.reversed().enumerated() {
            let toKey: String = through.to ?? {
                guard !through.isPivot else {
                    return nextTable.referenceKey
                }

                switch type {
                case .belongs:
                    return nextTable.referenceKey
                case .has:
                    return through.table.idKey
                }
            }()

            if nextKeyImplicit && through.isPivot {
                nextKey = nextTable.idKey
            }

            let join = SQLJoin(type: .inner, joinTable: through.table.string)
                .on(first: "\(through.table.string).\(toKey)", op: .equals, second: "\(nextTable.string).\(nextKey)")
            joins.append(join)

            nextTable = through.table
            previousTable = throughs[safe: index - 1]?.table ?? from.table

            nextKeyImplicit = through.from == nil
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
        throughs.append(Through(table: .string(table, keyMapping: db.keyMapping), from: from, to: to, isPivot: isPivot))
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
        let toTable = throughs.first?.table.string ?? to.table.string
        let toColumn: String = throughs.first?.from ?? to.key ?? {
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
        if !throughs.isEmpty {
            lookupKey = "\(toTable).\(toColumn)"
            lookupAlias = "__lookup"
            columns.append("\(lookupKey) as \(lookupAlias)")
        }

        let fromColumn: String = from.key ?? {
            switch type {
            case .belongs:
                return nextTable.referenceKey
            case .has:
                return thisTable.idKey
            }
        }()
        let inputValues = try input.map { try $0.require(fromColumn) }
        let results: [SQLRow] = try await query
            .where("\(lookupKey)", in: inputValues)
            .select(columns)

        let resultsByToColumn = results.grouped(by: \.[lookupAlias])
        return inputValues.map { resultsByToColumn[$0] ?? [] }
    }

    // MARK: Hashable

    public static func == (lhs: RelationshipQuery, rhs: RelationshipQuery) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(from)
        hasher.combine(to)
    }
}

// MARK: - Key Inference

struct Column: Hashable {
    struct Table: Hashable {
        let string: String
        let idKey: String
        let referenceKey: String

        static func model(_ model: (some Model).Type) -> Table {
            Table(string: model.tableName, idKey: model.idKey, referenceKey: model.referenceKey)
        }

        static func string(_ string: String, keyMapping: KeyMapping) -> Table {
            let id = keyMapping.encode("Id")
            let ref = keyMapping.encode(string.singularized + "Id")
            return Table(string: string, idKey: id, referenceKey: ref)
        }
    }

    let table: Table
    let key: String?
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

// MARK: - Query + Eager Loading

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

// MARK: Compoun Queries Loading

extension ModelRelationship {
    public subscript<T: RelationAllowed>(dynamicMember relationship: KeyPath<To.M, To.M.Relationship<T>>) -> From.Relationship<T> {
        // Could add a through, however it would be great to eager load the intermidiary relationship.
        fatalError()
    }
}
