
/*
 Parts:
 1. `SQLQuery`
    - SQL
    - Throughs
 2. Followup `SQLQuery`s

 Features
 1. SQL Load
 2. Realtionship
 3. Through
 4. Key overrides
 5. Cahcing
 6. Chaining
 */

/*
 Query
 - Has Steps, Depend on Eachother
 From -> To = 1 Query
 From -> Through -> To = 2 Queries
 */

struct Keys: Equatable {
    let idKey: String
    let referenceKey: String

    static func model(_ model: (some Model).Type) -> Keys {
        Keys(
            idKey: model.idKey,
            referenceKey: model.referenceKey
        )
    }

    static func table(_ table: String, from: (some Model).Type) -> Keys {
        Keys(
            idKey: from.keyMapping.map(input: "Id"),
            referenceKey: from.keyMapping.map(input: table.singularized + "Id")
        )
    }
}

/// The kind of relationship. Used only to determine to/from key defaults.
enum Relation {
    /// `From` is a child of `To`.
    case belongsTo
    /// `From` is a parent of `To`.
    case has
    /// `From` and `To` are parents of a separate pivot table.
    case pivot

    func defaultFromKey(from: Keys, to: Keys) -> String {
        switch self {
        case .has, .pivot:
            return from.idKey
        case .belongsTo:
            return to.referenceKey
        }
    }

    func defaultToKey(from: Keys, to: Keys) -> String {
        switch self {
        case .belongsTo, .pivot:
            return to.idKey
        case .has:
            return from.referenceKey
        }
    }
}

public struct QueryStep {
    public let fromTable: String
    public let fromKey: String
    public let toTable: String
    public let toKey: String
}

/// Computes the relationship across another table.
struct Through: Hashable {
    /// The table through which the relationship should go.
    let table: String
    /// Any user provided `fromKey`.
    let fromKeyOverride: String?
    /// Any user provided `toKey`.
    let toKeyOverride: String?
    /// The key defaults for the table.
    let tableKeys: Keys
    /// The type of relationship this through table is to the from table.
    let relation: Relation

    /// The from key to use when constructing the query.
    func fromKey(fromKeys: Keys) -> String {
        fromKeyOverride ?? relation.defaultToKey(from: fromKeys, to: tableKeys)
    }

    /// The to key to use when constructing the query.
    func toKey(toKeys: Keys) -> String {
        toKeyOverride ?? relation.defaultFromKey(from: tableKeys, to: toKeys)
    }

    func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(table)
        hasher.combine(fromKeyOverride)
        hasher.combine(toKeyOverride)
    }
}

@dynamicMemberLookup
public class RelationshipQuery<From: EagerLoadable, To: RelationAllowed>: Query<To.M>, Hashable {
    var fromModel: From
    var fromKeyOverride: String?
    var toKeyOverride: String?
    var relation: Relation

    // MARK: Through Scratch

    var throughs: [Through] = []

    func fromKey(to: Keys?) -> String {
        fromKeyOverride ?? relation.defaultFromKey(from: .model(From.self), to: to ?? .model(To.M.self))
    }

    func toKey(from: Keys?) -> String {
        toKeyOverride ?? relation.defaultToKey(from: from ?? .model(From.self), to: .model(To.M.self))
    }

    var isLoaded: Bool {
        fromModel.cacheExists(hashValue: hashValue)
    }

    init(db: Database = DB, fromModel: From, fromKey: String?, toKey: String?, relation: Relation) {
        self.fromModel = fromModel
        self.fromKeyOverride = fromKey
        self.toKeyOverride = toKey
        self.relation = relation
        super.init(db: db)
    }

    /// Fetches the value of this relationship.
    public func fetch() async throws -> To {
        try await _fetch(checkCache: true)
    }

    /// Sugar for `fetch()`.
    public func callAsFunction() async throws -> To {
        try await fetch()
    }

    public func sync() async throws -> To {
        try await _fetch(checkCache: false)
    }

    private func _fetch(checkCache: Bool) async throws -> To {
        if checkCache, let cached = try checkEagerLoadCache() {
            return cached
        } else {
            let results = try await get()
            let value = try To.from(array: results)
            fromModel.cache(hashValue: hashValue, value: value)
            return value
        }
    }

    /// Fetches any value from the relationship's eager loaded cache.
    private func checkEagerLoadCache() throws -> To? {
        guard let results = fromModel.cache?.relationships[hashValue] else {
            return nil
        }

        guard let castResults = results as? To else {
            throw RuneError("Eager loading type mismatch!")
        }

        return castResults
    }

    public override func get() async throws -> [To.M] {
        try await fetch(for: [fromModel]).first?.value ?? []
    }

    // THIS IS SOLID
    /// Calculate all step of this relationship. 1 query = 1 step.
    public func calculateSteps() -> [QueryStep] {
        var stepIndex = 0

        var allKeys: [Keys] = [.model(From.self)]
        allKeys.append(contentsOf: throughs.map(\.tableKeys))
        allKeys.append(.model(To.M.self))

        var steps: [QueryStep] = []

        var previousTable = From.tableName
        var previousKey = fromKey(to: allKeys[stepIndex + 1])

        for through in throughs {
            let nextKey = through.fromKey(fromKeys: allKeys[stepIndex])
            let nextTable = through.table
            steps.append(QueryStep(fromTable: previousTable, fromKey: previousKey, toTable: nextTable, toKey: nextKey))
            stepIndex += 1

            // Hop across same table.
            previousKey = through.toKey(toKeys: allKeys[stepIndex + 1])
            previousTable = through.table
        }

        let lastKey = toKey(from: allKeys[stepIndex])
        steps.append(QueryStep(fromTable: previousTable, fromKey: previousKey, toTable: table, toKey: lastKey))
        return steps
    }

    // THIS IS SOLID
    private func fetch(for fromModels: [From]) async throws -> [From.ID: [To.M]] {

        // 1. Calculate the steps of the query.
        let steps = calculateSteps()
        var fromRows = fromModels.compactMap(\.cache?.row)
        var idLookup: [From.ID: [SQLRow]] = [:]
        for fromModel in fromModels {
            if let row = fromModel.cache?.row {
                idLookup[fromModel.id] = [row]
            }
        }

        // 2. Evaluate each step.
        for step in steps {
            var fromKeyValues = fromRows
                .map(\.[step.fromKey])
                .filterUniqueValues()
            let stepResults = try await db
                .from(step.toTable)
                .where(step.toKey, in: fromKeyValues)
                .getRows()

            idLookup = idLookup
                .mapValues { previousResults in
                    let previousResultsKeys = previousResults.map(\.[step.fromKey])
                    return stepResults
                        .filter { previousResultsKeys.contains($0[step.toKey]) }
                }

            fromRows = stepResults
        }

        // 3. Decode the results.
        var toModelsByFromId = try idLookup.mapValues { try $0.mapDecode(To.M.self) }
        var toModelsEagerLoaded = try await didLoad(idLookup.flatMap { $0.value })

        // 4. Set eager loaded models in the results dict.
        toModelsByFromId = toModelsByFromId
            .mapValues { toModelsNotEagerLoaded in
                toModelsNotEagerLoaded.compactMap { toModelNotEagerLoaded in
                    toModelsEagerLoaded.first(where: { $0.id == toModelNotEagerLoaded.id })
                }
            }

        return toModelsByFromId
    }

    // THIS IS SOLID.
    func eagerLoad(on fromModels: inout [From]) async throws {
        // 1. Fetch relationships for all `fromModel`s.
        let toResults = try await fetch(for: fromModels)

        // 2. Cach relationship on relevant `fromModel`.
        var fromModelsEagerLoaded: [From] = []
        for var fromModel in fromModels {
            let toResults = toResults[fromModel.id] ?? []
            let toValue = try To.from(array: toResults)
            fromModel.cache(hashValue: hashValue, value: toValue)
            fromModelsEagerLoaded.append(fromModel)
        }

        fromModels = fromModelsEagerLoaded
    }

    // THIS IS SOLID.
    /// Returns any eager loaded value for this relationship or throws an error.
    public func require() throws -> To {
        guard let results = try checkEagerLoadCache() else {
            throw RuneError("Required relationship from `\(From.self)` to `\(To.self)` wasn't eager loaded!")
        }

        return results
    }

    // Through Model

    // SOLID
    public func through(_ model: (some Model).Type, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        through(model.tableName, from: fromKey, to: toKey)
    }

    // SOLID
    public func throughPivot(_ model: (some Model).Type, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        throughPivot(model.tableName, from: fromKey, to: toKey)
    }

    // Through table

    // SOLID
    public func throughPivot(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        self.relation = .pivot
        return through(table, from: fromKey ?? From.referenceKey, to: toKey ?? To.M.referenceKey)
    }

    // SOLID
    public func through(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        let through = Through(table: table,
                              fromKeyOverride: fromKey,
                              toKeyOverride: toKey,
                              tableKeys: .table(table, from: From.self),
                              relation: .has)
        throughs.append(through)
        return self
    }

    // MARK: Hashable

    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(From.tableName)
        hasher.combine(To.M.tableName)
        hasher.combine(fromKeyOverride)
        hasher.combine(toKeyOverride)
        hasher.combine(wheres)
    }

    func map<T: RelationAllowed>(mapper: @escaping (inout [To.M]) async throws -> [T.M]) -> RelationshipQuery<From, T> {
        // Copy to new query with different type
        let newQuery = RelationshipQuery<From, T>(db: db, fromModel: fromModel, fromKey: fromKeyOverride, toKey: toKeyOverride, relation: self.relation)
        print("SETTING TO \(table)")
        newQuery.table = table
        newQuery.shouldLog = shouldLog

        newQuery.columns = columns
        newQuery.isDistinct = isDistinct
        newQuery.limit = limit
        newQuery.offset = offset
        newQuery.lock = lock

        newQuery.joins = joins
        newQuery.wheres = wheres
        newQuery.groups = groups
        newQuery.havings = havings
        newQuery.orders = orders

        let _didLoad = didLoad
        newQuery.didLoad = { (rows: [SQLRow]) in
            print("GOT ROWS! \(rows.count)")
            var models = try await _didLoad(rows)
            let results = try await mapper(&models)
            return results
        }

        return newQuery
    }
}

extension RelationshipQuery where To.M: EagerLoadable {
    public subscript<T: RelationAllowed>(dynamicMember relationship: KeyPath<To.M, To.M.Relationship2<T>>) -> RelationshipQuery<From, T> {
        // 1. Construct Query from To -> T.
        // 2. Append to sub queries.
        // 3. return ref to new query for additional nesting.

        // Must return a custom query
        // 1. to the destination relationship (so the end type can be inferred for subsequent chains)
        // 2. but originating from the root relationship (so the whole thing can be set via didLoad)

        // 1. Inital Query
        // 2. Followup Queries
        return map { models in
            guard let first = models.first else {
                return []
            }

            let query = first[keyPath: relationship]
            try await query.eagerLoad(on: &models)
            return try models.flatMap { try $0[keyPath: relationship].require().toModel() }
        }
    }
}

extension Query where M: EagerLoadable {
    public func with2<T: RelationAllowed>(
        _ relationship: @escaping (M) -> M.Relationship2<T>,
        nested: @escaping ((M.Relationship2<T>) -> M.Relationship2<T>) = { $0 }
    ) -> Self {
        withLoad { models in
            guard let first = models.first else {
                return
            }

            let query = nested(relationship(first))
            try await query.eagerLoad(on: &models)
        }
    }
}

extension EagerLoadable {
    public typealias Relationship2<To: RelationAllowed> = RelationshipQuery<Self, To>

    public func hasMany<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<[To]> {
        Relationship2(db: DB, fromModel: self, fromKey: fromKey, toKey: toKey, relation: .has)
    }

    public func hasOne<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To> {
        Relationship2(db: DB, fromModel: self, fromKey: fromKey, toKey: toKey, relation: .has)
    }

    public func hasOne<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To?> {
        Relationship2(db: DB, fromModel: self, fromKey: fromKey, toKey: toKey, relation: .has)
    }

    public func belongsTo<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To> {
        Relationship2(db: DB, fromModel: self, fromKey: fromKey, toKey: toKey, relation: .belongsTo)
    }

    public func belongsTo<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To?> {
        Relationship2(db: DB, fromModel: self, fromKey: fromKey, toKey: toKey, relation: .belongsTo)
    }
}

/*
 1. Through Pivot

 users
 - id

 organizations
 - id

 user_organizations
 - id
 - user_id
 - organization_id

 2. Has Through

 users
 - id

 accounts
 - id
 - user_id

 transactions
 - id
 - account_id

 3. BelongsTo Through

 cards
 - id
 - account_id

 accounts
 - id
 - user_id

 users
 - id

 Other
 - ignore A belongs to B has C; mostly irrelevant.

 through -> infer keys based on same relationship on other side, must keep same "direction" or use another relationship.
 */

/*
 Through
 A -> D
 A -> B -> C -> D
 */

/*
 Each Through has the same key inference.

 Might decode through, might not.

 SIMPLE THINGS THAT COMPOSE

 1. Query fetches models.
 2. Relationship = query that fetches related models - auto filling in some query parameters.
    - instead of `Todo.where("user_id" == user.id).all()`, do `user.todos()`
 3. Through = query that fetches related models through joins across N tables.
    - instead of `Tag.join("todos", from: "todo_id", to: "id").where("todos.user_id" == user.id).all()`, `user.tags()`

 RelationshipQuery
 - through, updates `throughs` on the model.
 - on fetch,
    - compute inferred keys,
    - compute the entire query
    - compute which models to cach

 */

/*
 SUGAR
 1. `relationship.callAsFunction()` instead of `relationship.fetch()`.
 2. `relationship.otherRelationship` evaluates to `relationship.with(\.otherRelationship)` (so multiple eager loads).
 */

/*
 KeyPath support.

 Allow for multiple relationships loaded in one. Each get loaded / cached.

 */
