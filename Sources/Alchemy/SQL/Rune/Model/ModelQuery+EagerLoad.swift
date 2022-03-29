// MARK: Eager Loading

extension ModelQuery {
    /// A closure for defining any nested eager loading when loading a
    /// relationship on this `Model`.
    ///
    /// "Eager loading" refers to loading a model at the other end of
    /// a relationship of this queried model. Nested eager loads
    /// refers to loading a model from a relationship on that
    /// _other_ model.
    public typealias NestedEagerLoads<R: Model> = (ModelQuery<R>) -> ModelQuery<R>
    
    /// A tuple of models and the SQLRow that they were loaded from.
    typealias ModelRow = (model: M, row: SQLRow)
    
    /// Eager loads (loads a related `Model`) a `Relationship` on this
    /// model.
    ///
    /// Eager loads are evaluated in a single query per eager load
    /// after the initial model query has completed.
    ///
    /// Usage:
    /// ```swift
    /// // Consider three types, `Pet`, `Person`, and `Plant`. They
    /// // have the following relationships:
    /// struct Pet: Model {
    ///     ...
    ///     @BelongsTo var owner: Person
    /// }
    ///
    /// struct Person: Model {
    ///     ...
    ///     @BelongsTo var favoritePlant: Plant
    /// }
    ///
    /// struct Plant: Model { ... }
    ///
    /// // A `Pet` query that loads each pet's related owner _as well_
    /// // as those owners' favorite plants would look like this:
    /// Pet.query()
    ///     // An eager load
    ///     .with(\.$owner) { ownerQuery in
    ///         // `ownerQuery` is the query that will be run when
    ///         // fetching owner objects; we can give it its own
    ///         // eager loads (aka nested eager loading)
    ///         ownerQuery.with(\.$favoritePlant)
    ///     }
    ///     .getAll()
    /// ```
    /// - Parameters:
    ///   - relationshipKeyPath: The `KeyPath` of the relationship to
    ///     load. Please note that this is a `KeyPath` to a
    ///     `Relationship`, not a `Model`, so it will likely
    ///     start with a '$', such as `\.$user`.
    ///   - nested: A closure for any nested loading to do. See
    ///     example above. Defaults to an empty closure.
    /// - Returns: A query builder for extending the query.
    public func with<R: Relationship>(
        _ relationshipKeyPath: KeyPath<M, R>,
        nested: @escaping NestedEagerLoads<R.To.Value> = { $0 }
    ) -> ModelQuery<M> where R.From == M {
        eagerLoadQueries.append { fromResults in
            let mapper = RelationshipMapper<M>()
            M.mapRelations(mapper)
            let config = mapper.getConfig(for: relationshipKeyPath)
            
            // If there are no results, don't need to eager load.
            guard !fromResults.isEmpty else {
                return []
            }
            
            // Alias whatever key we'll join the relationship on
            let toJoinKeyAlias = "_to_join_key"
            let toJoinKey: String = {
                let table = config.through?.table ?? config.toTable
                let key = config.through?.fromKey ?? config.toKey
                return "\(table).\(key) as \(toJoinKeyAlias)"
            }()
            
            // Load the matching `To` rows
            let allRows = fromResults.map(\.row)
            let query = try nested(config.load(allRows, database: Database(provider: self.database)))
            let toResults = try await query
                .fetch(columns: ["\(R.To.Value.tableName).*", toJoinKey])
                .map { (model: try R.To.from($0), row: $1) }
            
            // Key the results by the join key value
            let toResultsKeyedByJoinKey = try Dictionary(grouping: toResults) { _, row in
                try row.require(toJoinKeyAlias)
            }
            
            // For each `from` populate it's relationship
            return try fromResults.map { model, row in
                let pk = try row.require(config.fromKey)
                let models = toResultsKeyedByJoinKey[pk]?.map(\.model) ?? []
                try model[keyPath: relationshipKeyPath].set(values: models)
                return (model, row)
            }
        }
        
        return self
    }
}

extension RelationshipMapping {
    fileprivate func load<M: Model>(_ values: [SQLRow], database: Database) throws -> ModelQuery<M> {
        var query = M.query(database: database)
        query.table = toTable
        var whereKey = "\(toTable).\(toKey)"
        if let through = through {
            whereKey = "\(through.table).\(through.fromKey)"
            query = query.leftJoin(table: through.table, first: "\(through.table).\(through.toKey)", second: "\(toTable).\(toKey)")
        }
        
        let ids = try values.map { try $0.require(fromKey).sqlValue }
        query = query.where(key: "\(whereKey)", in: ids.uniques)
        return query
    }
}

extension Array where Element: Hashable {
    /// Removes any duplicates from the array while maintaining the
    /// original order.
    fileprivate var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}


// MARK: - SCRATCH

extension Model {
    func with<R: Relationship>(db: Database = DB, _ relationship: KeyPath<Self, R>) async throws -> Self where R.From == Self {
        try await sync(db: db) { $0.with(relationship) }
    }
    
    func fetch<To>(db: Database = DB, _ relationship: KeyPath<Self, HasMany<To>>) async throws -> [To] {
        try await sync(db: db) { $0.with(relationship) }[keyPath: relationship].wrappedValue
    }
    
    func fetch<To>(db: Database = DB, _ relationship: KeyPath<Self, BelongsTo<To>>) async throws -> To {
        try await sync(db: db) { $0.with(relationship) }[keyPath: relationship].wrappedValue
    }
    
    func fetch<To>(db: Database = DB, _ relationship: KeyPath<Self, HasOne<To>>) async throws -> To {
        try await sync(db: db) { $0.with(relationship) }[keyPath: relationship].wrappedValue
    }
}

extension Array where Element: Model {
    public typealias ModelQueryConfig = (ModelQuery<Element>) -> ModelQuery<Element>
    
    func with<R: Relationship>(db: Database = DB, _ relationship: KeyPath<Element, R>) async throws -> Self where R.From == Element {
        try await syncAll(db: db) { $0.with(relationship) }
    }
    
    func fetchAll<To: RelationshipAllowed>(db: Database = DB, _ relationship: KeyPath<Element, Element.HasMany<To>>) async throws -> [To] {
        try await syncAll(db: db) { $0.with(relationship) }
            .flatMap { $0[keyPath: relationship].wrappedValue }
    }
    
    func fetchAll<To: RelationshipAllowed>(db: Database = DB, _ relationship: KeyPath<Element, Element.BelongsTo<To>>) async throws -> [To] {
        try await syncAll(db: db) { $0.with(relationship) }
            .map { $0[keyPath: relationship].wrappedValue }
    }
    
    func fetchAll<To: RelationshipAllowed>(db: Database = DB, _ relationship: KeyPath<Element, Element.HasOne<To>>) async throws -> [To] {
        try await syncAll(db: db) { $0.with(relationship) }
            .map { $0[keyPath: relationship].wrappedValue }
    }
}
