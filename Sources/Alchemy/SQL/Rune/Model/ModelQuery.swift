import Foundation
import NIO

public extension Model {
    /// Begin a `ModelQuery<Self>` from a given database.
    ///
    /// - Parameter database: The database to run the query on.
    ///   Defaults to `Database.default`.
    /// - Returns: A builder for building your query.
    static func query(database: Database = DB) -> ModelQuery<Self> {
        ModelQuery<Self>(database: database.provider, table: Self.tableName)
    }
}

/// A `ModelQuery` is just a subclass of `Query` with some added
/// typing and convenience functions for querying the table of
/// a specific `Model`.
public class ModelQuery<M: Model>: Query {
    typealias ModelRow = (model: M, row: SQLRow)
    
    /// The closures of any eager loads to run. To be run after the
    /// initial models of type `Self` are fetched.
    var eagerLoadQueries: [([ModelRow]) async throws -> [ModelRow]] = []
    
    // MARK: Fetching
    
    /// Gets all models matching this query from the database.
    ///
    /// - Returns: All models matching this query.
    public func all() async throws -> [M] {
        try await fetch().map(\.model)
    }
    
    /// Get the first model matching this query from the database.
    ///
    /// - Returns: The first model matching this query if one exists.
    public func first() async throws -> M? {
        try await limit(1).all().first
    }
    
    /// Similar to `firstModel`. Gets the first result of a query, but
    /// unwraps the element, throwing an error if it doesn't exist.
    ///
    /// - Parameter error: The error to throw should no element be
    ///   found. Defaults to `RuneError.notFound`.
    /// - Returns: The unwrapped first result of this query, or the
    ///   supplied error if no result was found.
    public func unwrapFirst(or error: Error = RuneError.notFound) async throws -> M {
        try await first().unwrap(or: error)
    }
    
    /// Returns a model of this query, if one exists.
    public func random() async throws -> M? {
        try await select().orderBy("RANDOM()").limit(1).first()
    }
    
    func fetch(columns: [String]? = ["\(M.tableName).*"]) async throws -> [ModelRow] {
        let initialResults = try await getRows(columns).map { (try $0.decode(M.self), $0) }
        let withEagerLoads = try await evaluateEagerLoads(for: initialResults)
        try await M.didFetch(withEagerLoads.map(\.model))
        return withEagerLoads
    }
    
    /// Evaluate all eager loads in this `ModelQuery` sequentially.
    /// This occurs after the inital `M` query has completed.
    ///
    /// - Parameter models: The models that were loaded by the initial
    ///   query.
    /// - Returns: The loaded models that will have all specified
    ///   relationships loaded.
    private func evaluateEagerLoads(for models: [ModelRow]) async throws -> [ModelRow] {
        var results: [ModelRow] = models
        for query in eagerLoadQueries {
            results = try await query(results)
        }
        
        return results
    }
}

extension Model {
    fileprivate static func didFetch(_ models: [Self]) async throws {
        try await ModelDidFetch(models: models).fire()
    }
}
