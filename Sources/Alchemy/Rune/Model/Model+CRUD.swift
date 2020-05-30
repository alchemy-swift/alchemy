import NIO

extension Model {
    static func all(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<[Self]> {
        Self.query(database: db)
            .getAll(on: loop)
    }
    
    /// Saves the `Model` to the `Database`. If the model's id is nil, it inserts it. If the id is
    /// not nil, it updates.
    func save(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        catchError(on: loop) {
            if let id = self.id {
                return try Self.query()
                    .where("id" == id)
                    .update(values: try self.dictionary().unorderedDictionary)
                    .voided()
            } else {
                return Self.query(database: db)
                    .insert(try self.dictionary())
                    .voided()
            }
        }
    }
    
    /// Deletes this model from the database.
    func delete(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        catchError(on: loop) {
            let idField = try self.idField()
            return Self.query(database: db)
                .where(WhereValue(key: idField.column, op: .equals, value: idField.value))
                .delete(on: loop)
                .voided()
        }
    }

    /// Reloads this item from the database and passes a new, updated object in an EventLoopFuture.
    func sync(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Self> {
        catchError(on: loop) {
            guard let id = self.id else {
                throw RuneError(info: "Can't sync an object without an `id`.")
            }

            return Self.query()
                .where("id" == id)
                .first()
                .flatMapThrowing { try $0.unwrap(or: RuneError(info: "Sync error: couldn't find a row on \(Self.tableName) with id \(id)")).decode(Self.self) }
        }
    }
}

extension Model {
    /// A tuple representing the column & value tuples of the type.
    func sqlData() throws -> (columns: [String], values: [DatabaseValue]) {
        var columns: [String] = []
        var values: [DatabaseValue] = []

        for field in try self.fields() {
            columns.append(field.column)
            values.append(field.value)
        }

        return (columns: columns, values: values)
    }
}

extension Array where Element: Model {
    /// Create or update each element in this array. Runs two queries; one to update & one to insert.
    func save(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        catchError(on: loop) {
            Element.query(database: db)
                .insert(try self.map { try $0.dictionary() })
                .voided()
        }
    }

    /// Delete all objects in this array.
    func delete(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        catchError(on: loop) {
            Element.query()
                .where(key: "id", in: self.compactMap { $0.id })
                .delete()
                .voided()
        }
    }
}
