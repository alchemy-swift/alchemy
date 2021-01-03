import Foundation
import NIO

public extension Model {
    /// Begin a `ModelQuery<Self>` from a given database of this model. `ModelQuery`s are just a
    /// subclass of `Query` with some added typing and convenience functions for querying the table
    /// of this specific `Model`.
    ///
    /// - Parameter database: the database to run the query on. Defaults to `DB.default`.
    /// - Returns: a builder for building your query.
    static func query(database: Database = DB.default) -> ModelQuery<Self> {
        ModelQuery<Self>(database: database).from(table: Self.tableName)
    }
}

/// A `ModelQuery` is just a subclass of `Query` with some added typing and convenience functions
/// for querying the table of a specific `Model`.
public class ModelQuery<M: Model>: Query {
    /// A closure for defining any nested eager loading when loading a relationship on this `Model`.
    ///
    /// "Eager loading" refers to loading a model at the other end of a relationship of this queried
    /// model. Nested eager loads refers to loading a model from a relationship on that _other_
    /// model.
    public typealias NestedEagerLoads<R: Model> = (ModelQuery<R>) -> ModelQuery<R>
    
    /// The closures of any eager loads to run. To be run after the initial models of type `Self`
    /// are fetched.
    ///
    /// -  Warning: Right now these only run when the query is finished with `getAll` or `getFirst`.
    ///             If the user finishes a query with a `get()` we don't know if/when the decode
    ///             will happen and how to handle it. A potential ways of doing this could be to
    ///             call eager loading @ the `.decode` level of a `DatabaseRow`, but that's too
    ///             complicated for now).
    private var eagerLoadQueries: [([M]) -> EventLoopFuture<[M]>] = []
    
    /// Gets all models matching this query from the database.
    ///
    /// - Returns: a future containing all models matching this query.
    public func getAll() -> EventLoopFuture<[M]> {
        self.get(["\(M.tableName).*"])
            .flatMapThrowing { try $0.map { try $0.decode(M.self) } }
            .flatMap { self.evaluateEagerLoads(for: $0) }
    }
    
    /// Get the first model matching this query from the database.
    ///
    /// - Returns: a future containing the first model matching this query or nil if this query has
    ///            no results.
    public func getFirst() -> EventLoopFuture<M?> {
        self.first(["\(M.tableName).*"])
            .flatMapThrowing { try $0?.decode(M.self) }
            .flatMap { result -> EventLoopFuture<M?> in
                if let result = result {
                    return self.evaluateEagerLoads(for: [result]).map { $0.first }
                } else {
                    return .new(nil)
                }
            }
    }
    
    /// Similary to `getFirst`. Gets the first result of a query, but unwraps the element, throwing
    /// an error if it doesn't exist.
    ///
    /// - Parameter error: the error to throw should no element be found. Defaults to
    ///                    `RuneError.notFound`.
    /// - Returns: a future containing the unwrapped first result of this query, or the supplied
    ///            error if no result was found.
    public func unwrapFirst(or error: Error = RuneError.notFound) -> EventLoopFuture<M> {
        self.getFirst()
            .flatMapThrowing { try $0.unwrap(or: error) }
    }
    
    /// Throws an error if a query with the specified where clause returns a value. The opposite of
    /// `unwrapFirstWhere(...)`.
    ///
    /// Useful for detecting if a value with a key that may conflict (such as a unique email)
    /// already exists on a table.
    ///
    /// - Parameters:
    ///   - where: the where clause to attempt to match.
    ///   - error: the error that will be thrown, should a query with the where clause find a
    ///            result.
    ///   - db: the database to query. Defaults to `DB.default`.
    /// - Returns: a future that will result in an error out if there is a row on the table matching
    ///            the given `where` clause.
    public static func ensureNotExists(
        _ where: WhereValue,
        else error: Error,
        db: Database = DB.default
    ) -> EventLoopFuture<Void> {
        Self.query(database: db)
            .where(`where`)
            .first()
            .flatMapThrowing { try $0.map { _ in throw error } }
    }
    
    /// Gets the first element that meets the given where value. Throws an error if no results
    /// match. The opposite of `ensureNotExists(...)`.
    ///
    /// - Parameters:
    ///   - where: the table will be queried for a row matching this clause.
    ///   - error: the error to throw should the query find no results.
    ///   - db: the database to query. Defaults to `DB.default`.
    /// - Returns: a future containing the first result matching the `where` clause. Will result in
    ///            `error` if no result is found.
    public static func unwrapFirstWhere(
        _ where: WhereValue,
        or error: Error,
        db: Database = DB.default
    ) -> EventLoopFuture<Self> {
        Self.query(database: db)
            .where(`where`)
            .unwrapFirst(or: error)
    }
    
    /// Eager loads (loads a related `Model`) a `Relationship` on this model.
    ///
    /// Eager loads are evaluated in a single query per eager load after the initial model query has
    /// completed.
    ///
    /// - Warning: **PLEASE NOTE** Eager loads only load when your query is completed with functions
    ///            from `ModelQuery`, such as `getAll` or `getFirst`. If you finish your query with
    ///            functions from `Query`, such as `delete`, `insert`, `save`, or `get`, the `Model`
    ///            type isn't guaranteed to be decoded so we can't run the eager loads.
    ///            **TL;DR**: only finish your query with functions that automatically decode your
    ///            model when using eager loads (i.e. doesn't result in
    ///            `EventLoopFuture<[DatabaseRow]>`).
    ///
    /// Usage:
    /// ```
    /// /// Consider three types, `Pet`, `Person`, and `Plant`. They have the following
    /// /// relationships:
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
    /// /// A `Pet` query that loads each pet's related owner _as well_ as those owners' favorite
    /// /// plants would look like this:
    /// Pet.query()
    ///     // An eager load
    ///     .with(\.$owner) { ownerQuery in
    ///         // `ownerQuery` is the query that will be run when fetching owner objects; we can
    ///         // give it its own eager loads (aka nested eager loading)
    ///         ownerQuery.with(\.$favoritePlant)
    ///     }
    ///     .getAll()
    /// ```
    /// - Parameters:
    ///   - relationshipKeyPath: the `KeyPath` of the relationship to load. Please note that this is
    ///                          a `KeyPath` to a `Relationship`, not a `Model`, so it will likely
    ///                          start with a '$', such as `\.$user`.
    ///   - nested: a closure for any nested loading to do. See example above. Defaults to an empty
    ///             closure.
    /// - Returns: a query builder for extending the query.
    public func with<R: Relationship>(
        _ relationshipKeyPath: KeyPath<M, R>,
        nested: @escaping NestedEagerLoads<R.To.Value> = { $0 }
    ) -> ModelQuery<M> where R.From == M {
        self.eagerLoadQueries.append { results in
            // If there are no results, don't need to eager load.
            guard let firstResult = results.first else {
                return .new([])
            }

            return firstResult[keyPath: relationshipKeyPath]
                .loadRelationships(for: results, query: nested, into: relationshipKeyPath)
        }
        
        return self
    }

    /// Evaluate all eager loads in this `ModelQuery` sequentially. This occurs after the inital
    /// `M` query has completed.
    ///
    /// - Parameter models: the models that were loaded by the initial query.
    /// - Returns: a future containing the loaded models that will have all specified relationships
    ///            loaded.
    private func evaluateEagerLoads(for models: [M]) -> EventLoopFuture<[M]> {
        self.eagerLoadQueries
            .reduce(.new(models)) { future, eagerLoad in
                future.flatMap { eagerLoad($0) }
            }
    }
}
