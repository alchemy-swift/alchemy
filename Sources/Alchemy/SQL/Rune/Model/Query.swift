import Foundation
import NIO

/*
 1. Run query.
 2. Run eager loads.
 3. When accessing relationships, check eager loaded properties. Else retrieve on the fly.
 */

public extension Model {
    /// Begin a `Query<Self>` from a given database.
    ///
    /// - Parameter database: The database to run the query on.
    ///   Defaults to `Database.default`.
    /// - Returns: A builder for building your query.
    static func query(db: Database = DB) -> Query<Self> {
        Query(db: db)
    }
}

/// A `Query` is just a subclass of `Query` with some added
/// typing and convenience functions for querying the table of
/// a specific `Model`.
public class Query<M: Model>: SQLQuery {
    /// The closures of any eager loads to run. To be run after the
    /// initial models of type `Self` are fetched.
    var eagerLoadQueries: [([ModelRow]) async throws -> [ModelRow]] = []

    var eagerLoads: [(inout [M]) async throws -> Void] = []

    /*
     1. Load initial models.
     2. Run query with loaded models.
     3. Set specific models keyed by relationship query.
     */

    init(db: Database) {
        super.init(db: db, table: M.tableName)
    }
    
    // MARK: Fetching

    /// Gets all models matching this query from the database.
    ///
    /// - Returns: All models matching this query.
    public func get() async throws -> [M] {
        try await _get()
    }

    /// Gets all models matching this query from the database.
    ///
    /// - Returns: All models matching this query.
    public func all() async throws -> [M] {
        try await get()
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
    
    func _get(columns: [String]? = ["\(M.tableName).*"]) async throws -> [M] {
        // Get Initial rows.
        var models = try await getRows(columns).map { try $0.decode(M.self) }
        // Eager load.
        print("There are \(eagerLoads.count) eager loads to evaluate")
        for load in eagerLoads {
            try await load(&models)
        }

        return models
    }
    
    /// Evaluate all eager loads in this `Query` sequentially.
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
