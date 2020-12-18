import NIO

extension Model {
    /// Get all of the models of this type.
    public static func all(db: Database = DB.default) -> EventLoopFuture<[Self]> {
        Self.query(database: db)
            .getAll()
    }
    
    /// Saves the `Model` to the `Database`. If the model's id is nil, it inserts it. If the id is
    /// not nil, it updates.
    public func save(db: Database = DB.default) -> EventLoopFuture<Self> {
        catchError {
            if let id = self.id {
                return try Self.query()
                    .where("id" == id)
                    .update(values: try self.fieldDictionary().unorderedDictionary)
                    .map { _ in self }
            } else {
                return Self.query(database: db)
                    .insert(try self.fieldDictionary())
                    .flatMapThrowing { try $0.first.unwrap(or: RuneError(info: "Unable to find first element.")) }
                    .flatMapThrowing { try $0.decode(Self.self) }
            }
        }
    }
    
    /// Deletes this model from the database.
    public func delete(db: Database = DB.default) -> EventLoopFuture<Void> {
        catchError {
            let idField = try self.getID()
            return Self.query(database: db)
                .where("id" == idField)
                .delete()
                .voided()
        }
    }

    /// Reloads this item from the database and passes a new, updated object in an EventLoopFuture.
    public func sync(db: Database = DB.default) -> EventLoopFuture<Self> {
        catchError {
            guard let id = self.id else {
                throw RuneError(info: "Can't sync an object without an `id`.")
            }

            return Self.query()
                .where("id" == id)
                .first()
                .flatMapThrowing { try $0.unwrap(or: RuneError(info: "Sync error: couldn't find a row on \(Self.tableName) with id \(id)")).decode(Self.self) }
        }
    }
    
    /// Throws an error if a query with the specified where clause returns a value.
    ///
    /// Useful for detecting if a value with a conflicting key already exists.
    public static func ensureNotExist(_ where: WhereValue, else error: Error) -> EventLoopFuture<Void> {
        Self.query()
            .where(`where`)
            .first()
            .flatMapThrowing { try $0.map { _ in throw error } }
    }
    
    /// Gets the first element that meets the given where value. Throws an error if no results match.
    public static func unwrapFirstWhere(_ where: WhereValue, or error: Error) -> EventLoopFuture<Self> {
        Self.query()
            .where(`where`)
            .unwrapFirst(or: error)
    }
}

extension Array where Element: Model {
    /// Create or update each element in this array. Runs two queries; one to update & one to insert.
    public func save(db: Database = DB.default) -> EventLoopFuture<Self> {
        catchError {
            Element.query(database: db)
                .insert(try self.map { try $0.fieldDictionary() })
                .map { _ in self }
        }
    }

    /// Delete all objects in this array.
    public func delete(db: Database = DB.default) -> EventLoopFuture<Void> {
        catchError {
            Element.query()
                .where(key: "id", in: self.compactMap { $0.id })
                .delete()
                .voided()
        }
    }
}
