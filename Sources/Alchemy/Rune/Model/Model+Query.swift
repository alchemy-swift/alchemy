import Foundation
import NIO

public extension Model {
    /// Begin a `ModelQuery<Self>` from a given database.
    ///
    /// - Parameter database: The database to run the query on.
    ///   Defaults to `Database.default`.
    /// - Returns: A builder for building your query.
    static func query(database: Database = .default) -> ModelQuery<Self> {
        ModelQuery<Self>(database: database.driver).from(table: Self.tableName)
    }
}

/// A `ModelQuery` is just a subclass of `Query` with some added
/// typing and convenience functions for querying the table of
/// a specific `Model`.
public class ModelQuery<M: Model>: Query {
    /// A closure for defining any nested eager loading when loading a
    /// relationship on this `Model`.
    ///
    /// "Eager loading" refers to loading a model at the other end of
    /// a relationship of this queried model. Nested eager loads
    /// refers to loading a model from a relationship on that
    /// _other_ model.
    public typealias NestedEagerLoads<R: Model> = (ModelQuery<R>) -> ModelQuery<R>
    
    /// The closures of any eager loads to run. To be run after the
    /// initial models of type `Self` are fetched.
    ///
    /// -  Warning: Right now these only run when the query is
    ///    finished with `allModels` or `firstModel`. If the user
    ///    finishes a query with a `get()` we don't know if/when the
    ///    decode will happen and how to handle it. A potential ways
    ///    of doing this could be to call eager loading @ the
    ///    `.decode` level of a `DatabaseRow`, but that's too
    ///    complicated for now).
    private var eagerLoadQueries: [([(M, DatabaseRow)]) -> EventLoopFuture<[(M, DatabaseRow)]>] = []
    
    /// Gets all models matching this query from the database.
    ///
    /// - Returns: A future containing all models matching this query.
    public func allModels() -> EventLoopFuture<[M]> {
        self._allModels().mapEach(\.0)
    }
    
    private func _allModels(columns: [Column]? = ["\(M.tableName).*"]) -> EventLoopFuture<[(M, DatabaseRow)]> {
        return self.get(columns)
            .flatMapThrowing {
                try $0.map { (try $0.decode(M.self), $0) }
            }
            .flatMap { self.evaluateEagerLoads(for: $0) }
    }
    
    /// Get the first model matching this query from the database.
    ///
    /// - Returns: A future containing the first model matching this
    ///   query or nil if this query has no results.
    public func firstModel() -> EventLoopFuture<M?> {
        self.first()
            .flatMapThrowing { result -> (M, DatabaseRow)? in
                guard let result = result else {
                    return nil
                }
                
                return (try result.decode(M.self), result)
            }
            .flatMap { result -> EventLoopFuture<(M, DatabaseRow)?> in
                if let result = result {
                    return self.evaluateEagerLoads(for: [result]).map { $0.first }
                } else {
                    return .new(nil)
                }
            }
            .map { $0?.0 }
    }
    
    /// Similary to `getFirst`. Gets the first result of a query, but
    /// unwraps the element, throwing an error if it doesn't exist.
    ///
    /// - Parameter error: The error to throw should no element be
    ///   found. Defaults to `RuneError.notFound`.
    /// - Returns: A future containing the unwrapped first result of
    ///   this query, or the supplied error if no result was found.
    public func unwrapFirst(or error: Error = RuneError.notFound) -> EventLoopFuture<M> {
        self.firstModel()
            .flatMapThrowing { try $0.unwrap(or: error) }
    }
    
    /// Eager loads (loads a related `Model`) a `Relationship` on this
    /// model.
    ///
    /// Eager loads are evaluated in a single query per eager load
    /// after the initial model query has completed.
    ///
    /// - Warning: **PLEASE NOTE** Eager loads only load when your
    ///   query is completed with functions from `ModelQuery`, such as
    ///   `allModels` or `firstModel`. If you finish your query with
    ///   functions from `Query`, such as `delete`, `insert`, `save`,
    ///   or `get`, the `Model` type isn't guaranteed to be decoded so
    ///   we can't run the eager loads. **TL;DR**: only finish your
    ///   query with functions that automatically decode your model
    ///   when using eager loads (i.e. doesn't result in
    ///   `EventLoopFuture<[DatabaseRow]>`).
    ///
    /// Usage:
    /// ```swift
    /// // Consider three types, `Pet`, `Person`, and `Plant`. They
    /// // have the following relationships:
    /// struct Pet: Model {
    ///     ...
    ///
    ///     @BelongsTo
    ///     var owner: Person
    /// }
    ///
    /// struct Person: Model {
    ///     ...
    ///
    ///     @BelongsTo
    ///     var favoritePlant: Plant
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
        self.eagerLoadQueries.append { fromResults in
            catchError {
                let mapper = RelationshipMapper<M>()
                M.mapRelations(mapper)
                let config = mapper.getConfig(for: relationshipKeyPath)
                
                // If there are no results, don't need to eager load.
                guard !fromResults.isEmpty else {
                    return .new([])
                }
                
                // Alias whatever key we'll join the relationship on
                let toJoinKeyAlias = "_to_join_key"
                let toJoinKey: String = {
                    let table = config.through?.table ?? config.toTable
                    let key = config.through?.fromKey ?? config.toKey
                    return "\(table).\(key) as \(toJoinKeyAlias)"
                }()
                
                let allRows = fromResults.map(\.1)
                return nested(try config.load(allRows))
                    ._allModels(columns: ["\(R.To.Value.tableName).*", toJoinKey])
                    .flatMapEachThrowing { (try R.To.from($0), $1) }
                    // Key the results by the "from" identifier
                    .flatMapThrowing {
                        try Dictionary(grouping: $0) { _, row in
                            try row.getField(column: toJoinKeyAlias).value
                        }
                    }
                    // For each `from` populate it's relationship
                    .flatMapThrowing { toResultsKeyedByFromId in
                        return try fromResults.map { model, row in
                            let pk = try row.getField(column: config.fromKey).value
                            let models = toResultsKeyedByFromId[pk]?.map(\.0) ?? []
                            try model[keyPath: relationshipKeyPath].set(values: models)
                            return (model, row)
                        }
                    }
            }
        }
        
        return self
    }

    /// Evaluate all eager loads in this `ModelQuery` sequentially.
    /// This occurs after the inital `M` query has completed.
    ///
    /// - Parameter models: The models that were loaded by the initial
    ///   query.
    /// - Returns: A future containing the loaded models that will
    ///   have all specified relationships loaded.
    private func evaluateEagerLoads(for models: [(M, DatabaseRow)]) -> EventLoopFuture<[(M, DatabaseRow)]> {
        self.eagerLoadQueries
            .reduce(.new(models)) { future, eagerLoad in
                future.flatMap { eagerLoad($0) }
            }
    }
}

private extension RelationshipMapping {
    func load<M: Model>(_ values: [DatabaseRow]) throws -> ModelQuery<M> {
        var query = M.query().from(table: toTable)
        var whereKey = "\(toTable).\(toKey)"
        if let through = through {
            whereKey = "\(through.table).\(through.fromKey)"
            query = query.leftJoin(table: through.table, first: "\(through.table).\(through.toKey)", second: "\(toTable).\(toKey)")
        }

        let ids = try values.map { try $0.getField(column: fromKey).value }
        query = query.where(key: "\(whereKey)", in: ids.uniques)
        return query
    }
}

private extension Array where Element: Hashable {
    /// Removes any duplicates from the array while maintaining the
    /// original order.
    var uniques: Array {
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
