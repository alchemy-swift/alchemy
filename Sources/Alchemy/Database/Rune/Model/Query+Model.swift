import Foundation
import NIO

/// A `Query` is just a subclass of `Query` with some added
/// typing and convenience functions for querying the table of
/// a specific `Model`.
extension Query where Result: Model {

    // MARK: Fetching

    /// Gets all models matching this query from the database.
    ///
    /// - Returns: All models matching this query.
    public func all() async throws -> [Result] {
        try await get()
    }
    
    /// Get the first model matching this query from the database.
    ///
    /// - Returns: The first model matching this query if one exists.
    public func first() async throws -> Result? {
        try await limit(1).all().first
    }
    
    /// Similar to `firstModel`. Gets the first result of a query, but
    /// unwraps the element, throwing an error if it doesn't exist.
    ///
    /// - Parameter error: The error to throw should no element be
    ///   found. Defaults to `RuneError.notFound`.
    /// - Returns: The unwrapped first result of this query, or the
    ///   supplied error if no result was found.
    public func unwrapFirst(or error: Error = RuneError.notFound) async throws -> Result {
        try await first().unwrap(or: error)
    }
    
    /// Returns a model of this query, if one exists.
    public func random() async throws -> Result? {
        try await select().orderBy("RANDOM()").limit(1).first()
    }
}

extension Model {
    /// Begin a `Query<Self>` from a given database.
    ///
    /// - Parameter database: The database to run the query on.
    ///   Defaults to `Database.default`.
    /// - Returns: A builder for building your query.
    public static func query(db: Database = DB) -> Query<Self> {
        db.table(Self.self)
    }

    // TODO: Re-enable this
    fileprivate static func didFetch(_ models: [Self]) async throws {
        try await ModelDidFetch(models: models).fire()
    }
}

extension Database {
    public func table<M: Model>(_ model: M.Type, as alias: String? = nil) -> Query<M> {
        let tableName = alias.map { "\(model.table) AS \($0)" } ?? model.table
        return Query(db: self, table: tableName)
    }
}
