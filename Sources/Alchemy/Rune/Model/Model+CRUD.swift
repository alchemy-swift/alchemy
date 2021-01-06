import NIO

/// Useful extensions for various CRUD operations of a `Model`.
extension Model {
    /// Load all models of this type from a database.
    ///
    /// - Parameter db: the database to load models from. Defaults to `Services.db`.
    /// - Returns: an `EventLoopFuture` with an array of this model, loaded from the database.
    public static func all(db: Database = Services.db) -> EventLoopFuture<[Self]> {
        Self.query(database: db)
            .getAll()
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
    ///   - db: the database to query. Defaults to `Services.db`.
    /// - Returns: a future that will result in an error out if there is a row on the table matching
    ///            the given `where` clause.
    public static func ensureNotExists(
        _ where: WhereValue,
        else error: Error,
        db: Database = Services.db
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
    ///   - db: the database to query. Defaults to `Services.db`.
    /// - Returns: a future containing the first result matching the `where` clause. Will result in
    ///            `error` if no result is found.
    public static func unwrapFirstWhere(
        _ where: WhereValue,
        or error: Error,
        db: Database = Services.db
    ) -> EventLoopFuture<Self> {
        Self.query(database: db)
            .where(`where`)
            .unwrapFirst(or: error)
    }
    
    /// Saves this model to a database. If this model's `id` is nil, it inserts it. If the `id`
    /// is not nil, it updates.
    ///
    /// - Parameter db: the database to save this model to. Defaults to `Services.db`.
    /// - Returns: a future that contains an updated version of self with an updated copy of this
    ///            model, reflecting any changes that may have occurred saving this object to the
    ///            database (an `id` being populated, for example).
    public func save(db: Database = Services.db) -> EventLoopFuture<Self> {
        catchError {
            if let id = self.id {
                return try Self.query(database: db)
                    .where("id" == id)
                    .update(values: try self.fieldDictionary().unorderedDictionary)
                    .map { _ in self }
            } else {
                return Self.query(database: db)
                    .insert(try self.fieldDictionary())
                    .flatMapThrowing {
                        try $0.first.unwrap(or: RuneError.notFound)
                    }
                    .flatMapThrowing { try $0.decode(Self.self) }
            }
        }
    }
    
    /// Deletes this model from a database. This will fail if the model has a nil `id` field.
    ///
    /// - Parameter db: the database to remove this model from. Defaults to `Services.db`.
    /// - Returns: a future that completes when the model has been deleted.
    public func delete(db: Database = Services.db) -> EventLoopFuture<Void> {
        catchError {
            let idField = try self.getID()
            return Self.query(database: db)
                .where("id" == idField)
                .delete()
                .voided()
        }
    }

    /// Fetches an copy of this model from a database, with any updates that may have been made
    /// since it was last fetched.
    ///
    /// - Parameter db: the database to load from. Defaults to `Services.db`.
    /// - Returns: a future containing a freshly synced copy of this model.
    public func sync(db: Database = Services.db) -> EventLoopFuture<Self> {
        catchError {
            guard let id = self.id else {
                throw RuneError.syncErrorNoId
            }

            return Self.query(database: db)
                .where("id" == id)
                .first()
                .flatMapThrowing {
                    try $0.unwrap(or: RuneError.syncErrorNoMatch(table: Self.tableName, id: id))
                        .decode(Self.self)
                }
        }
    }
}

/// Usefuly extensions for CRUD operations on an array of `Model`s.
extension Array where Element: Model {
    /// Inserts each element in this array to a database.
    ///
    /// - Parameter db: the database to insert the models into. Defaults to `Services.db`.
    /// - Returns: a future that contains copies of all models in this array, updated to reflect any
    ///            changes in the model caused by inserting.
    public func insert(db: Database = Services.db) -> EventLoopFuture<Self> {
        catchError {
            Element.query(database: db)
                .insert(try self.map { try $0.fieldDictionary() })
                .flatMapEachThrowing { try $0.decode(Element.self) }
        }
    }

    /// Deletes all objects in this array from a database. If an object in this array isn't actually
    /// in the database, it will be ignored.
    ///
    /// - Parameter db: the database to delete from. Defaults to `Services.db`.
    /// - Returns: a future that completes when all models in this array are deleted from the
    ///            database.
    public func delete(db: Database = Services.db) -> EventLoopFuture<Void> {
        Element.query(database: db)
            .where(key: "id", in: self.compactMap { $0.id })
            .delete()
            .voided()
    }
}
