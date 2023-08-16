import NIO

/// Useful extensions for various CRUD operations of a `Model`.
extension Model {

    // MARK: - SELECT

    /// Load all models of this type from a database.
    ///
    /// - Parameter db: The database to load models from. Defaults to
    ///   `Database.default`.
    /// - Returns: An array of this model, loaded from the database.
    public static func all(on db: Database = database) async throws -> [Self] {
        try await query(on: db).get()
    }

    public static func chunk(on db: Database = database, _ chunkSize: Int = 100, handler: ([Self]) async throws -> Void) async throws {
        try await query(on: db).chunk(chunkSize, handler: handler)
    }

    public static func lazy(on db: Database = database, _ chunkSize: Int = 100) -> LazyQuerySequence<Self> {
        query(on: db).lazy(chunkSize)
    }

    /// Fetch the first model with the given id.
    ///
    /// - Parameters:
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to find.
    /// - Returns: A matching model, if one exists.
    public static func find(on db: Database = database, _ id: Identifier) async throws -> Self? {
        try await `where`(on: db, primaryKey == id).first()
    }
    
    /// Fetch the first model that matches the given where clause.
    ///
    /// - Parameters:
    ///   - where: A where clause for filtering models.
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    /// - Returns: A matching model, if one exists.
    public static func first(on db: Database = database, where: SQLWhere.Clause) async throws -> Self? {
        try await Self.where(on: db, `where`).first()
    }

    /// Fetch the first model of this type.
    ///
    /// - Parameters: db: The database to search the model for.
    ///   Defaults to `Database.default`.
    /// - Returns: The first model, if one exists.
    public static func first(db: Database = database) async throws -> Self? {
        try await query(on: db).first()
    }

    /// Similar to `firstModel`. Gets the first result of a query, but
    /// unwraps the element, throwing an error if it doesn't exist.
    ///
    /// - Parameter error: The error to throw should no element be
    ///   found. Defaults to `RuneError.notFound`.
    /// - Returns: The unwrapped first result of this query, or the
    ///   supplied error if no result was found.
    public static func require(_ id: Identifier, error: Error = RuneError.notFound, db: Database = database) async throws -> Self {
        try await find(on: db, id).unwrap(or: error)
    }

    /// Returns a random model of this type, if one exists.
    public static func random(on db: Database = database) async throws -> Self? {
        try await query(on: db).random()
    }

    // MARK: - INSERT

    /// Inserts this model to a database.
    ///
    /// - Parameter db: The database to insert this model to. Defaults
    ///   to `Database.default`.
    public func insert(on db: Database = database) async throws {
        try await [self].insertAll(on: db)
    }
    
    /// Inserts this model to a database. Return the newly created model.
    ///
    /// - Parameter db: The database to insert this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: An updated version of this model, reflecting any
    ///   changes that may have occurred saving this object to the
    ///   database. (an `id` being populated, for example).
    public func insertReturn(on db: Database = database) async throws -> Self {
        let model = try await [self].insertReturnAll(on: db).first.unwrap(or: RuneError.notFound)
        self.row = model.row
        self.id.value = model.id.value
        return model
    }
    
    // MARK: - UPDATE

    /// Update this model in a database.
    ///
    /// - Parameter db: The database to update this model to. Defaults
    ///   to `Database.default`.
    /// - Returns: An updated version of this model, reflecting any
    ///   changes that may have occurred saving this object to the
    ///   database.
    @discardableResult
    public func update(on db: Database = database) async throws -> Self {
        let fields = try dirtyFields()
        try await [self].updateAll(on: db, fields)
        return try await refresh(on: db)
    }
    
    @discardableResult
    public func update(on db: Database = database, updateClosure: (inout Self) -> Void) async throws -> Self {
        var copy = self
        updateClosure(&copy)
        return try await copy.update(on: db)
    }
    
    @discardableResult
    public func update(on db: Database = database, _ fields: [String: Any]) async throws -> Self {
        let values = fields.compactMapValues { $0 as? SQLConvertible }
        return try await update(on: db, values)
    }

    @discardableResult
    public func update(on db: Database = database, _ fields: [String: SQLConvertible]) async throws -> Self {
        try await [self].updateAll(on: db, fields)
        return try await refresh(on: db)
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
    public func save(on db: Database = database) async throws -> Self {
        if row == nil {
            return try await insertReturn(on: db)
        } else {
            return try await update(on: db)
        }
    }
    
    // MARK: - DELETE

    /// Deletes this model from a database. This will fail if the
    /// model has a nil `id` field.
    ///
    /// - Parameter db: The database to remove this model from.
    ///   Defaults to `Database.default`.
    public func delete(on db: Database = database) async throws {
        try await [self].deleteAll(on: db)
    }
    
    /// Delete all models that match the given where clause.
    ///
    /// - Parameters:
    ///   - db: The database to fetch the model from. Defaults to
    ///     `Database.default`.
    ///   - where: A where clause to filter models.
    public static func delete(on db: Database = database, _ where: SQLWhere.Clause) async throws {
        try await query(on: db).where(`where`).delete()
    }
    
    /// Delete the first model with the given id.
    ///
    /// - Parameters:
    ///   - db: The database to delete the model from. Defaults to
    ///     `Database.default`.
    ///   - id: The id of the model to delete.
    public static func delete(on db: Database = database, _ id: Self.Identifier) async throws {
        try await query(on: db).where(primaryKey == id).delete()
    }
    
    /// Delete all models of this type from a database.
    ///
    /// - Parameter
    ///   - db: The database to delete models from. Defaults
    ///     to `Database.default`.
    ///   - where: An optional where clause to specify the elements
    ///     to delete.
    public static func truncate(on db: Database = database) async throws {
        try await query(on: db).delete()
    }

    // MARK: - Refresh

    /// Fetches an copy of this model from a database, with any
    /// updates that may have been made since it was last
    /// fetched.
    ///
    /// - Parameter db: The database to load from. Defaults to
    ///   `Database.default`.
    /// - Returns: A freshly synced copy of this model.
    public func refresh(on db: Database = database) async throws -> Self {
        let model = try await Self.require(id.require())
        self.row = model.row
        return model
    }

    // MARK: Query

    /// Creates a query on the given model with the given where
    /// clause.
    ///
    /// - Parameters:
    ///   - where: A clause to match.
    ///   - db: The database to query. Defaults to `Database.default`.
    /// - Returns: A query on the `Model`'s table that matches the
    ///   given where clause.
    public static func `where`(on db: Database = database, _ where: SQLWhere.Clause) -> Query<Self> {
        query(on: db).where(`where`)
    }

    public static func select(on db: Database = database, _ columns: String...) -> Query<Self> {
        query(on: db).select(columns)
    }

    public static func with<E: EagerLoadable>(on db: Database = database, _ loader: @escaping (Self) -> E) -> Query<Self> where E.From == Self {
        query(on: db).didLoad { models in
            guard let first = models.first else { return }
            try await loader(first).load(on: models)
        }
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
    public func insertAll(on db: Database = Element.database) async throws {
        try await Element.willCreate(self)
        try await Element.query(on: db).insert(try insertableFields(on: db))
        try await Element.didCreate(self)
    }
    
    /// Inserts and returns each element in this array to a database.
    ///
    /// - Parameter db: The database to insert the models into.
    ///   Defaults to `Database.default`.
    /// - Returns: All models in array, updated to reflect any changes
    ///   in the model caused by inserting.
    public func insertReturnAll(on db: Database = Element.database) async throws -> Self {
        try await Element.willCreate(self)
        let results = try await Element.query(on: db)
            .insertReturn(try insertableFields(on: db))
            .map { try $0.decodeModel(Element.self) }
        try await Element.didCreate(results)
        return results
    }

    @discardableResult
    public func updateAll(on db: Database = Element.database, _ fields: [String: Any]) async throws -> Self {
        let values = fields.compactMapValues { $0 as? SQLConvertible }
        return try await updateAll(on: db, values)
    }

    public func updateAll(on db: Database = Element.database, _ fields: [String: SQLConvertible]) async throws {
        let ids = map(\.id)
        let fields = touchUpdatedAt(on: db, fields)
        try await Element.willUpdate(self)
        try await Element.query(on: db)
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
    public func deleteAll(on db: Database = Element.database) async throws {
        let ids = map(\.id)
        try await Element.willDelete(self)
        try await Element.query(on: db)
            .where(Element.primaryKey, in: ids)
            .delete()
        try await Element.didDelete(self)
    }
    
    public func refreshAll(on db: Database = Element.database) async throws -> Self {
        guard !isEmpty else {
            return self
        }

        guard allSatisfy({ $0.id.value != nil }) else {
            throw RuneError.syncErrorNoId
        }

        let ids = map(\.id)
        return try await Element.query()
            .where(Element.primaryKey, in: ids)
            .get()
    }
    
    private func touchUpdatedAt(on db: Database, _ fields: [String: SQLConvertible]) -> [String: SQLConvertible] {
        guard let timestamps = Element.self as? Timestamped.Type else {
            return fields
        }
        
        var fields = fields
        fields[db.keyMapping.encode(timestamps.updatedAtKey)] = .now
        return fields
    }
    
    private func insertableFields(on db: Database) throws -> [[String: SQLConvertible]] {
        guard let timestamps = Element.self as? Timestamped.Type else {
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
    static func didFetch(_ models: [Self]) async throws {
        try await ModelDidFetch(models: models).fire()
    }

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
