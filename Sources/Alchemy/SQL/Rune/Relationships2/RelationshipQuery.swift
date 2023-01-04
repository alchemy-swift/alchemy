//@dynamicMemberLookup
public class RelationshipQuery<From: EagerLoadable, To: RelationAllowed>: Query<To.M>, Hashable {
    /// The kind of relationship. Used only to determine to/from key defaults.
    enum Relation {
        /// `From` is a child of `To`.
        case belongsTo
        /// `From` is a parent of `To`.
        case has
        /// `From` and `To` are parents of a separate pivot table.
        case pivot

        func defaultFromKey() -> String {
            switch self {
            case .has, .pivot:
                return From.idKey
            case .belongsTo:
                return To.M.referenceKey
            }
        }

        func defaultToKey() -> String {
            switch self {
            case .belongsTo, .pivot:
                return To.M.idKey
            case .has:
                return From.referenceKey
            }
        }
    }

    var from: From
    var fromKeyOverride: String?
    var toKeyOverride: String?
    var relation: Relation

    var fromKey: String {
        fromKeyOverride ?? relation.defaultFromKey()
    }

    var toKey: String {
        toKeyOverride ?? relation.defaultToKey()
    }


    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(From.tableName)
        hasher.combine(To.M.tableName)
        hasher.combine(fromKey)
        hasher.combine(toKey)
        hasher.combine(wheres)
    }

    init(db: Database = DB, from: From, fromKey: String?, toKey: String?, relation: Relation) {
        self.from = from
        self.fromKeyOverride = fromKey
        self.toKeyOverride = toKey
        self.relation = relation
        super.init(db: db)
    }

    private func loadChildren(for parents: [From]) async throws -> Zip2Sequence<[SQLRow], [To.M]> {
        // Evaluate throughs
        var parentKeys = parents.compactMap(\.cache?.row).map(\.[fromKey]).filterUniqueValues()
        for through in throughs {
            print("> parent keys \(parentKeys.compactMap(\.?.description))")
            print("> \(through.table) \(through.fromKey) \(through.toKey)")
            parentKeys = try await db
                .from(through.table)
                .where(through.fromKey, in: parentKeys)
                .getRows()
                .map(\.[fromKey])
                .filterUniqueValues()
        }

        // Fetch children.
        let childRows = try await super.where(toKey, in: parentKeys).getRows()
        var childModels = try childRows.mapDecode(To.M.self)
        for load in eagerLoads {
            try await load(&childModels)
        }

        return zip(childRows, childModels)
    }

    func eagerLoad(on parents: inout [From]) async throws {
        let hashValue = hashValue

        // Cache children on each parent.
        let children = try await loadChildren(for: parents)
        var results: [From] = []
        for var parent in parents {
            let fromValue = parent.cache?.row[fromKey]
            let matchingChildModels = children.filter { $0.0[toKey] == fromValue }.map(\.1)
            let relationshipValue = try To.from(array: matchingChildModels)
            parent.cache(hashValue: hashValue, value: relationshipValue)
            results.append(parent)
        }

        parents = results
    }

    public override func get() async throws -> [To.M] {
        if let cached = try checkEagerLoadCache() {
            return cached
        } else {
            return try await loadChildren(for: [from]).map(\.1)
        }
    }

    /// Fetches the value of this relationship.
    public func fetch() async throws -> To {
        let hashValue = hashValue
        let value = try await To.from(array: get())
        from.cache(hashValue: hashValue, value: value)
        return value
    }

    /// Returns any eager loaded value for this relationship or throws an error.
    public func require() throws -> To {
        guard let results = try checkEagerLoadCache() else {
            throw RuneError("Required relationship from `\(From.self)` to `\(To.self)` wasn't eager loaded!")
        }

        return try To.from(array: results)
    }

    /// Fetches any value from the relationship's eager loaded cache.
    private func checkEagerLoadCache() throws -> [To.M]? {
        guard let results = from.cache?.relationships[hashValue] else {
            return nil
        }

        guard let castResults = results as? [To.M] else {
            throw RuneError("Eager loading type mismatch!")
        }

        return castResults
    }

    // MARK: Through Scratch

    var throughs: [Through] = []

    struct Through: Hashable {
        let table: String
        let fromKeyOverride: String?
        let toKeyOverride: String?
        let relation: Relation

        // TODO: Somehow get wheres / other queries here
        // TODO: Finish default keys (need to look @ next through potentially...? Decide @ query time? Might want some special logic for this.)

        func hash(into hasher: inout Swift.Hasher) {
            hasher.combine(table)
            hasher.combine(fromKeyOverride)
            hasher.combine(toKeyOverride)
            hasher.combine(relation)
        }
    }

    // Through from other relationship (allows custom query) convenience

//    public subscript<T: RelationAllowed>(dynamicMember child: KeyPath<To, To.M.Relationship2<T>>) -> RelationshipQuery<From, T> where To.M: EagerLoadable {
//        through { $0[keyPath: child] }
//    }

    // Through from other relationship (allows custom query)

//    func through<T: RelationAllowed>(closure: @escaping (To) -> RelationshipQuery<To.M, T>) -> RelationshipQuery<From, T> {

        /*
         1. Users
         2. Repositories
         3. Workflows
         4. Jobs
         */

        /*
         A relationship may have a previous relationship that needs to be
         loaded first.
         */

//        user
//            .hasMany(Repository.self)
//            .hasMany(Workflow.self)
//            .hasMany(Job.self)
//
//        user
//            .through("repostiories") // from, to, table
//            .through("workflows") // from, to, table
//            .hasMany(Job.self)

        // Ignore types and jsut store to from / through. Then closure to cache intermediary relationships.

//        let copy = RelationshipQuery<From, T>.init(from: from, fromKey: fromKey, toKey: toKey)
//        copy.through = { firstChild in
//            try await closure(self.fetch()).fetch()
//        }

//        return copy
//    }

    // Through Model

    func through(_ model: (some Model).Type, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        through(model.tableName, from: fromKey, to: toKey)
    }

    func throughPivot(_ model: (some Model).Type, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        self.relation = .pivot
        return throughPivot(model.tableName, from: fromKey, to: toKey)
    }

    // Through table

    func through(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        let through = Through(table: table, fromKeyOverride: fromKey, toKeyOverride: toKey, relation: relation)
        throughs.append(through)
        return self
    }

    func throughPivot(_ table: String, from fromKey: String? = nil, to toKey: String? = nil) -> Self {
        through(table, from: fromKey ?? From.referenceKey, to: toKey ?? To.M.referenceKey)
    }
}

extension Query where M: EagerLoadable {
    public func with<To: RelationAllowed>(
        _ relationship: @escaping (M) -> M.Relationship2<To>,
        nested: @escaping ((M.Relationship2<To>) -> M.Relationship2<To>) = { $0 }
    ) -> Self {
        let load: (inout [M]) async throws -> Void = { parents in
            guard let first = parents.first else {
                return
            }

            let query = nested(relationship(first))
            try await query.eagerLoad(on: &parents)
        }

        eagerLoads.append(load)
        return self
    }
}

extension EagerLoadable {
    public typealias Relationship2<To: RelationAllowed> = RelationshipQuery<Self, To>

    public func hasMany<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<[To]> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey, relation: .has)
    }

    public func hasOne<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey, relation: .has)
    }

    public func hasOne<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To?> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey, relation: .has)
    }

    public func belongsTo<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey, relation: .belongsTo)
    }

    public func belongsTo<To: Model>(_ type: To.Type = To.self, from fromKey: String? = nil, to toKey: String? = nil) -> Relationship2<To?> {
        Relationship2(db: DB, from: self, fromKey: fromKey, toKey: toKey, relation: .belongsTo)
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
