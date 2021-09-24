import NIO

/// Useful extensions for various CRUD operations of a `Model`.
extension Model {
    /// Load all models of this type from a database.
    ///
    /// - Parameter db: The database to load models from. Defaults to
    ///   `Database.default`.
    /// - Returns: An `EventLoopFuture` with an array of this model,
    ///   loaded from the database.
    public static func all(db: Database = .default) -> EventLoopFuture<[Self]> {
        Self.query(database: db)
            .allModels()
    }
    
    /// Fetch the first model with the given id.
    ///
    /// - Parameters:
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to find.
    /// - Returns: A future with a matching model.
    public static func find(db: Database = .default, _ id: Self.Identifier) -> EventLoopFuture<Self?> {
        Self.firstWhere("id" == id, db: db)
    }
    
    /// Fetch the first model with the given id, throwing the given
    /// error if it doesn't exist.
    ///
    /// - Parameters:
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to find.
    ///   - error: An error to throw if the model doesn't exist.
    /// - Returns: A future with a matching model.
    public static func find(db: Database = .default, _ id: Self.Identifier, or error: Error) -> EventLoopFuture<Self> {
        Self.firstWhere("id" == id, db: db).unwrap(orError: error)
    }
    
    /// Delete the first model with the given id.
    ///
    /// - Parameters:
    ///   - db: The database to delete the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to delete.
    /// - Returns: A future that completes when the model is deleted.
    public static func delete(db: Database = .default, _ id: Self.Identifier) -> EventLoopFuture<Void> {
        query().where("id" == id).delete().voided()
    }
    
    /// Delete all models of this type from a database.
    ///
    /// - Parameter
    ///   - db: The database to delete models from. Defaults
    ///     to `Database.default`.
    ///   - where: An optional where clause to specify the elements
    ///     to delete.
    /// - Returns: A future that completes when the models are
    ///   deleted.
    public static func deleteAll(db: Database = .default, where: WhereValue? = nil) -> EventLoopFuture<Void> {
        var query = Self.query(database: db)
        if let clause = `where` { query = query.where(clause) }
        return query.delete().voided()
    }
    
    /// Throws an error if a query with the specified where clause
    /// returns a value. The opposite of `unwrapFirstWhere(...)`.
    ///
    /// Useful for detecting if a value with a key that may conflict
    /// (such as a unique email) already exists on a table.
    ///
    /// - Parameters:
    ///   - where: The where clause to attempt to match.
    ///   - error: The error that will be thrown, should a query with
    ///     the where clause find a result.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: A future that will result in an error out if there
    ///   is a row on the table matching the given `where` clause.
    public static func ensureNotExists(
        _ where: WhereValue,
        else error: Error,
        db: Database = .default
) -> EventLoopFuture<Void> {
        Self.query(database: db)
            .where(`where`)
            .first()
            .flatMapThrowing { try $0.map { _ in throw error } }
    }
    
    /// Creates a query on the given model with the given where
    /// clause.
    ///
    /// - Parameters:
    ///   - where: A clause to match.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: A query on the `Model`'s table that matches the
    ///   given where clause.
    public static func `where`(_ where: WhereValue, db: Database = .default) -> ModelQuery<Self> {
        Self.query(database: db)
            .where(`where`)
    }
    
    /// Gets the first element that meets the given where value.
    ///
    /// - Parameters:
    ///   - where: The table will be queried for a row matching this
    ///     clause.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: A future containing the first result matching the
    ///   `where` clause, if one exists.
    public static func firstWhere(_ where: WhereValue, db: Database = .default) -> EventLoopFuture<Self?> {
        Self.query(database: db)
            .where(`where`)
            .firstModel()
    }
    
    /// Gets all elements that meets the given where value.
    ///
    /// - Parameters:
    ///   - where: The table will be queried for a row matching this
    ///     clause.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: A future containing all the results matching the
    ///   `where` clause.
    public static func allWhere(_ where: WhereValue, db: Database = .default) -> EventLoopFuture<[Self]> {
        Self.query(database: db)
            .where(`where`)
            .allModels()
    }
    
    /// Gets the first element that meets the given where value.
    /// Throws an error if no results match. The opposite of
    /// `ensureNotExists(...)`.
    ///
    /// - Parameters:
    ///   - where: The table will be queried for a row matching this
    ///     clause.
    ///   - error: The error to throw if there are no results.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: A future containing the first result matching the
    ///   `where` clause. Will result in `error` if no result is
    ///   found.
    public static func unwrapFirstWhere(
        _ where: WhereValue,
        or error: Error,
        db: Database = .default
    ) -> EventLoopFuture<Self> {
        Self.query(database: db)
            .where(`where`)
            .unwrapFirst(or: error)
    }
    
    /// Saves this model to a database. If this model's `id` is nil,
    /// it inserts it. If the `id` is not nil, it updates.
    ///
    /// - Parameter db: The database to save this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: A future that contains an updated version of self
    ///   with an updated copy of this model, reflecting any changes
    ///   that may have occurred saving this object to the database
    ///   (an `id` being populated, for example).
    public func save(db: Database = .default) -> EventLoopFuture<Self> {
        if self.id != nil {
            return self.update(db: db)
        } else {
            return self.insert(db: db)
        }
    }
    
    /// Update this model in a database.
    ///
    /// - Parameter db: The database to update this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: A future that contains an updated version of self
    ///   with an updated copy of this model, reflecting any changes
    ///   that may have occurred saving this object to the database.
    public func update(db: Database = .default) -> EventLoopFuture<Self> {
        return catchError {
            let id = try self.getID()
            return Self.query(database: db)
                .where("id" == id)
                .update(values: try self.fieldDictionary().unorderedDictionary)
                .map { _ in self }
        }
    }
    
    public func update(db: Database = .default, updateClosure: (inout Self) -> Void) -> EventLoopFuture<Self> {
        return catchError {
            let id = try self.getID()
            var copy = self
            updateClosure(&copy)
            return Self.query(database: db)
                .where("id" == id)
                .update(values: try copy.fieldDictionary().unorderedDictionary)
                .map { _ in copy }
        }
    }
    
    public static func update(db: Database = .default, _ id: Identifier, with dict: [String: Any]?) -> EventLoopFuture<Self?> {
        Self.find(id)
            .optionalFlatMap { $0.update(with: dict ?? [:]) }
    }
    
    public func update(db: Database = .default, with dict: [String: Any]) -> EventLoopFuture<Self> {
        Self.query()
            .where("id" == id)
            .update(values: dict.compactMapValues { $0 as? Parameter })
            .flatMap { _ in self.sync() }
    }
    
    /// Inserts this model to a database.
    ///
    /// - Parameter db: The database to insert this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: A future that contains an updated version of self
    ///   with an updated copy of this model, reflecting any changes
    ///   that may have occurred saving this object to the database.
    ///   (an `id` being populated, for example).
    public func insert(db: Database = .default) -> EventLoopFuture<Self> {
        catchError {
            Self.query(database: db)
                .insert(try self.fieldDictionary())
                .flatMapThrowing { try $0.first.unwrap(or: RuneError.notFound) }
                .flatMapThrowing { try $0.decode(Self.self) }
        }
    }
    
    /// Deletes this model from a database. This will fail if the
    /// model has a nil `id` field.
    ///
    /// - Parameter db: The database to remove this model from.
    ///   Defaults to `Database.default`.
    /// - Returns: A future that completes when the model has been
    ///   deleted.
    public func delete(db: Database = .default) -> EventLoopFuture<Void> {
        catchError {
            let idField = try self.getID()
            return Self.query(database: db)
                .where("id" == idField)
                .delete()
                .voided()
        }
    }

    /// Fetches an copy of this model from a database, with any
    /// updates that may have been made since it was last
    /// fetched.
    ///
    /// - Parameter db: The database to load from. Defaults to
    ///   `Database.default`.
    /// - Returns: A future containing a freshly synced copy of this
    ///   model.
    public func sync(db: Database = .default, query: ((ModelQuery<Self>) -> ModelQuery<Self>) = { $0 }) -> EventLoopFuture<Self> {
        catchError {
            guard let id = self.id else {
                throw RuneError.syncErrorNoId
            }

            return query(Self.query(database: db).where("id" == id))
                .firstModel()
                .unwrap(orError: RuneError.syncErrorNoMatch(table: Self.tableName, id: id))
        }
    }
}

/// Usefuly extensions for CRUD operations on an array of `Model`s.
extension Array where Element: Model {
    /// Inserts each element in this array to a database.
    ///
    /// - Parameter db: The database to insert the models into.
    ///   Defaults to `Database.default`.
    /// - Returns: A future that contains copies of all models in this
    ///   array, updated to reflect any changes in the model caused by inserting.
    public func insertAll(db: Database = .default) -> EventLoopFuture<Self> {
        catchError {
            Element.query(database: db)
                .insert(try self.map { try $0.fieldDictionary() })
                .flatMapEachThrowing { try $0.decode(Element.self) }
        }
    }

    /// Deletes all objects in this array from a database. If an
    /// object in this array isn't actually in the database, it
    /// will be ignored.
    ///
    /// - Parameter db: The database to delete from. Defaults to
    ///   `Database.default`.
    /// - Returns: A future that completes when all models in this
    ///   array are deleted from the database.
    public func deleteAll(db: Database = .default) -> EventLoopFuture<Void> {
        Element.query(database: db)
            .where(key: "id", in: self.compactMap { $0.id })
            .delete()
            .voided()
    }
}
