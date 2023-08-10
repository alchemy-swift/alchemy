import NIO

/// Useful extensions for various CRUD operations of a `Model`.
extension Model {
    
    // MARK: - Fetch
    
    /// Load all models of this type from a database.
    ///
    /// - Parameter db: The database to load models from. Defaults to
    ///   `Database.default`.
    /// - Returns: An array of this model, loaded from the database.
    public static func all(db: Database = DB) async throws -> [Self] {
        try await Self.query(db: db).all()
    }
    
    /// Fetch the first model with the given id.
    ///
    /// - Parameters:
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to find.
    /// - Returns: A matching model, if one exists.
    public static func find(_ id: Self.Identifier, db: Database = DB) async throws -> Self? {
        try await Self.firstWhere(Self.primaryKey == id, db: db)
    }
    
    /// Fetch the first model that matches the given where clause.
    ///
    /// - Parameters:
    ///   - where: A where clause for filtering models.
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    /// - Returns: A matching model, if one exists.
    public static func find(_ where: SQLWhere.Clause, db: Database = DB) async throws -> Self? {
        try await Self.firstWhere(`where`, db: db)
    }
    
    /// Fetch the first model with the given id, throwing the given
    /// error if it doesn't exist.
    ///
    /// - Parameters:
    ///   - db: The database to delete the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to delete.
    ///   - error: An error to throw if the model doesn't exist.
    /// - Returns: A matching model.
    public static func find(db: Database = DB, _ id: Self.Identifier, or error: Error) async throws -> Self {
        try await Self.firstWhere(Self.primaryKey == id, db: db).unwrap(or: error)
    }
    
    /// Fetch the first model of this type.
    ///
    /// - Parameters: db: The database to search the model for.
    ///   Defaults to `Database.default`.
    /// - Returns: The first model, if one exists.
    public static func first(db: Database = DB) async throws -> Self? {
        try await Self.query(db: db).first()
    }
    
    /// Returns a random model of this type, if one exists.
    public static func random(db: Database = DB) async throws -> Self? {
        // Note; MySQL should be `RAND()`
        try await Self.query(db: db).random()
    }
    
    /// Gets the first element that meets the given where value.
    ///
    /// - Parameters:
    ///   - where: The table will be queried for a row matching this
    ///     clause.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: The first result matching the `where` clause, if
    ///   one exists.
    public static func firstWhere(_ where: SQLWhere.Clause, db: Database = DB) async throws -> Self? {
        try await Self.query(db: db).where(`where`).first()
    }
    
    /// Gets all elements that meets the given where value.
    ///
    /// - Parameters:
    ///   - where: The table will be queried for a row matching this
    ///     clause.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: All the models matching the `where` clause.
    public static func allWhere(_ where: SQLWhere.Clause, db: Database = DB) async throws -> [Self] {
        try await Self.where(`where`, db: db).all()
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
    /// - Returns: The first result matching the `where` clause.
    public static func unwrapFirstWhere(_ where: SQLWhere.Clause, or error: Error, db: Database = DB) async throws -> Self {
        try await Self.where(`where`, db: db).unwrapFirst(or: error)
    }
    
    /// Creates a query on the given model with the given where
    /// clause.
    ///
    /// - Parameters:
    ///   - where: A clause to match.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: A query on the `Model`'s table that matches the
    ///   given where clause.
    public static func `where`(_ where: SQLWhere.Clause, db: Database = DB) -> Query<Self> {
        Self.query(db: db).where(`where`)
    }
    
    // MARK: - Insert
    
    /// Inserts this model to a database.
    ///
    /// - Parameter db: The database to insert this model to. Defaults
    ///   to `Database.default`.
    public func insert(db: Database = DB) async throws {
        try await [self].insertAll(db: db)
    }
    
    /// Inserts this model to a database. Return the newly created model.
    ///
    /// - Parameter db: The database to insert this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: An updated version of this model, reflecting any
    ///   changes that may have occurred saving this object to the
    ///   database. (an `id` being populated, for example).
    public func insertReturn(db: Database = DB) async throws -> Self {
        try await [self].insertReturnAll(db: db).first.unwrap(or: RuneError.notFound)
    }
    
    // MARK: - Update
    
    /// Update this model in a database.
    ///
    /// - Parameter db: The database to update this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: An updated version of this model, reflecting any
    ///   changes that may have occurred saving this object to the
    ///   database.
    @discardableResult
    public func update(db: Database = DB) async throws -> Self {
        let fields = try fields()
        try await [self].updateAll(db: db, fields)
        return try await refresh(db: db)
    }
    
    @discardableResult
    public func update(db: Database = DB, updateClosure: (inout Self) -> Void) async throws -> Self {
        var copy = self
        updateClosure(&copy)
        return try await copy.update(db: db)
    }
    
    @discardableResult
    public func update(db: Database = DB, _ fields: [String: Any]) async throws -> Self {
        let values = fields.compactMapValues { $0 as? SQLConvertible }
        return try await update(db: db, values)
    }

    @discardableResult
    public func update(db: Database = DB, _ fields: [String: SQLConvertible]) async throws -> Self {
        try await [self].updateAll(db: db, fields)
        return try await refresh(db: db)
    }

    @discardableResult
    public static func update(db: Database = DB, _ id: Identifier, fields: [String: Any]) async throws -> Self? {
        try await Self.find(id, db: db)?.update(db: db, fields)
    }
    
    // MARK: - Save
    
    /// Saves this model to a database. If this model's `id` is nil,
    /// it inserts it. If the `id` is not nil, it updates.
    ///
    /// - Parameter db: The database to save this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: An updated version of this model, reflecting any
    ///   changes that may have occurred saving this object to the
    ///   database (an `id` being populated, for example).
    @discardableResult
    public func save(db: Database = DB) async throws -> Self {
        guard id != nil else {
            return try await insertReturn(db: db)
        }
        
        return try await update(db: db)
    }
    
    // MARK: - Delete
    
    /// Deletes this model from a database. This will fail if the
    /// model has a nil `id` field.
    ///
    /// - Parameter db: The database to remove this model from.
    ///   Defaults to `Database.default`.
    public func delete(db: Database = DB) async throws {
        try await [self].deleteAll(db: db)
    }
    
    /// Delete all models that match the given where clause.
    ///
    /// - Parameters:
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    ///   - where: A where clause to filter models.
    public static func delete(_ where: SQLWhere.Clause, db: Database = DB) async throws {
        try await query(db: db).where(`where`).delete()
    }
    
    /// Delete the first model with the given id.
    ///
    /// - Parameters:
    ///   - db: The database to delete the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to delete.
    public static func delete(db: Database = DB, _ id: Self.Identifier) async throws {
        try await query(db: db).where(Self.primaryKey == id).delete()
    }
    
    /// Delete all models of this type from a database.
    ///
    /// - Parameter
    ///   - db: The database to delete models from. Defaults
    ///     to `Database.default`.
    ///   - where: An optional where clause to specify the elements
    ///     to delete.
    public static func deleteAll(db: Database = DB, where: SQLWhere.Clause? = nil) async throws {
        var query = Self.query(db: db)
        if let clause = `where` { query = query.where(clause) }
        try await query.delete()
    }
    
    // MARK: - Refresh

    /// Fetches an copy of this model from a database, with any
    /// updates that may have been made since it was last
    /// fetched.
    ///
    /// - Parameter db: The database to load from. Defaults to
    ///   `Database.default`.
    /// - Returns: A freshly synced copy of this model.
    public func refresh(db: Database = DB) async throws -> Self {
        try await Self.query(db: db)
            .where(Self.primaryKey == id)
            .first()
            .unwrap(or: RuneError.syncErrorNoMatch(table: Self.table, id: id))
    }
    
    // MARK: - Misc
    
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
    public static func ensureNotExists(_ where: SQLWhere.Clause, else error: Error, db: Database = DB) async throws {
        try await Self.query(db: db).where(`where`).first()
            .map { _ in throw error }
    }
}

// MARK: - Array Extensions

/// Usefuly extensions for CRUD operations on an array of `Model`s.
extension Array where Element: Model {
    /// Inserts each element in this array to a database.
    ///
    /// - Parameter db: The database to insert the models into.
    ///   Defaults to `Database.default`.
    /// - Returns: All models in array, updated to reflect any changes
    ///   in the model caused by inserting.
    public func insertAll(db: Database = DB) async throws {
        try await Element.willCreate(self)
        try await Element.query(db: db).insert(try insertableFields(db: db))
        try await Element.didCreate(self)
    }
    
    /// Inserts and returns each element in this array to a database.
    ///
    /// - Parameter db: The database to insert the models into.
    ///   Defaults to `Database.default`.
    /// - Returns: All models in array, updated to reflect any changes
    ///   in the model caused by inserting.
    public func insertReturnAll(db: Database = DB) async throws -> Self {
        try await Element.willCreate(self)
        let results = try await Element.query(db: db)
            .insertReturn(try insertableFields(db: db))
            .map { try $0.decodeModel(Element.self) }
        try await Element.didCreate(results)
        return results
    }
    
    public func updateAll(db: Database = DB, _ fields: [String: SQLConvertible]) async throws {
        let ids = map(\.id)
        let fields = touchUpdatedAt(fields, db: db)
        try await Element.willUpdate(self)
        try await Element.query(db: db)
            .where(Element.primaryKey, in: ids)
            .update(fields)
        try await Element.didUpdate(self)
    }
    
    /// Deletes all objects in this array from a database. If an
    /// object in this array isn't actually in the database, it
    /// will be ignored.
    ///
    /// - Parameter db: The database to delete from. Defaults to
    ///   `Database.default`.
    public func deleteAll(db: Database = DB) async throws {
        let ids = map(\.id)
        try await Element.willDelete(self)
        try await Element.query(db: db)
            .where(Element.primaryKey, in: ids)
            .delete()
        try await Element.didDelete(self)
    }
    
    public func syncAll(db: Database = DB) async throws -> Self {
        guard !isEmpty else {
            return self
        }

        guard allSatisfy({ $0.id != nil }) else {
            throw RuneError.syncErrorNoId
        }

        let ids = map(\.id)
        return try await Element.query()
            .where(Element.primaryKey, in: ids)
            .all()
    }
    
    private func touchUpdatedAt(_ fields: [String: SQLConvertible], db: Database) -> [String: SQLConvertible] {
        guard let timestamps = Element.self as? Timestamps.Type else {
            return fields
        }
        
        var fields = fields
        fields[db.keyMapping.encode(timestamps.updatedAtKey)] = .now
        return fields
    }
    
    private func insertableFields(db: Database) throws -> [[String: SQLConvertible]] {
        guard let timestamps = Element.self as? Timestamps.Type else {
            return try map { try $0.fields() }
        }

        return try map {
            var fields = try $0.fields()
            fields[db.keyMapping.encode(timestamps.createdAtKey)] = .now
            fields[db.keyMapping.encode(timestamps.updatedAtKey)] = .now
            return fields
        }
    }
}

// MARK: Model Events

extension Model {
    fileprivate static func willCreate(_ models: [Self]) async throws {
        try await ModelWillCreate(models: models).fire()
        try await willSave(models)
    }
    
    fileprivate static func didCreate(_ models: [Self]) async throws {
        try await ModelDidCreate(models: models).fire()
        try await didSave(models)
    }
    
    fileprivate static func willUpdate(_ models: [Self]) async throws {
        try await ModelWillUpdate(models: models).fire()
        try await willSave(models)
    }
    
    fileprivate static func didUpdate(_ models: [Self]) async throws {
        try await ModelDidUpdate(models: models).fire()
        try await didSave(models)
    }
    
    fileprivate static func willDelete(_ models: [Self]) async throws {
        try await ModelWillDelete(models: models).fire()
    }
    
    fileprivate static func didDelete(_ models: [Self]) async throws {
        try await ModelDidDelete(models: models).fire()
    }
    
    private static func willSave(_ models: [Self]) async throws {
        try await ModelWillSave(models: models).fire()
    }
    
    private static func didSave(_ models: [Self]) async throws {
        try await ModelDidSave(models: models).fire()
    }
}
