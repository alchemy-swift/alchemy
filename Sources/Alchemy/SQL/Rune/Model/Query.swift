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
    // Any actions to run after the SQLQuery is run, such as decoding models or
    // executing eager loads.
    var didLoad: ([SQLRow]) async throws -> [M] = {
        print("DECODE: \(M.self)")
        return try $0.mapDecode(M.self)
    }

    init(db: Database) {
        super.init(db: db, table: M.tableName)
    }

    // MARK: Loading

    func withLoad(loader: @escaping (inout [M]) async throws -> Void) -> Self {
        let _didLoad = didLoad
        didLoad = { rows in
            var models = try await _didLoad(rows)
            try await loader(&models)
            return models
        }

        return self
    }

    // MARK: Fetching

    /// Gets all models matching this query from the database.
    ///
    /// - Returns: All models matching this query.
    public func get() async throws -> [M] {
        // Load models.
        try await didLoad(getRows())
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
}

extension Model {
    fileprivate static func didFetch(_ models: [Self]) async throws {
        try await ModelDidFetch(models: models).fire()
    }
}
