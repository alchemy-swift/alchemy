import NIO

extension Model {
    static func all(db: Database = DB.default, loop: EventLoop = Loop.current)
        -> EventLoopFuture<[Self]>
    {
        Self.query(database: db)
            .get(on: loop)
    }
    
    /// Saves the `Model` to the `Database`. If the model's id is nil, it inserts it. If the id is
    /// not nil, it updates.
    func save(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        catchError(on: loop) {
            let fields = try self.fields()
            if self.existsInDatabase {
                let setString = fields
                    .compactMap { $0.column != "id" ? $0 : nil }
                    .enumerated()
                    .map { index, value in "\(value.column) = $\(index + 1)" }
                    .joined(separator: ", ")

                let statement = """
                UPDATE \(Self.tableName)
                SET \(setString)
                WHERE id = $\(fields.count)
                """

                return db.runQuery(statement, values: fields.map { $0.value } + [], on: loop)
                    .voided()
            } else {
                let columnsString = fields.map { $0.column }.joined(separator: ", ")
                let valuesString = fields.enumerated()
                    .map { index, _ in "$\(index + 1)" }
                    .joined(separator: ", ")

                let statement = """
                INSERT INTO \(Self.tableName) (\(columnsString))
                VALUES (\(valuesString))
                """
                return db.runQuery(statement, values: fields.map { $0.value }, on: loop)
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
            let idField = try self.idField()
            return Self.query()
                .where(WhereValue(key: "id", op: .equals, value: idField.value))
                .first()
                .flatMapThrowing { try $0.unwrap(or: RuneError(info: "Sync error: couldn't find a row on \(Self.tableName) with id \(idField.value)")).decode(Self.self) }
        }
    }
}

extension Model {
    /// A tuple representing the column & value tuples of the type.
    func sqlStrings() throws -> (columns: [String], values: [DatabaseValue]) {
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
            guard let first = self.first else {
                return loop.future()
            }

            let columnsString = try first.fields().map { $0.column }.joined(separator: ", ")

            var insertValues: [[DatabaseValue]] = []
            var updateValues: [[DatabaseValue]] = []

            for model in self {
                if model.id == nil {
                    insertValues.append(try model.sqlStrings().values)
                } else {
                    throw RuneError(info: "Only inserts are supported for bulk save for now ;_;")
                    updateValues.append(try model.sqlStrings().values)
                }
            }

            var offset = 0
            let insertValuesString = insertValues
                .map { "(\($0.map { _ in "$\(offset += 1)" }.joined(separator: ", ")))" }
                .joined(separator: ",\n")

            let insertString = """
            INSERT INTO \(Element.tableName)
                (\(columnsString))
            VALUES
                \(insertValuesString)
            """

            return db.runQuery(insertString, values: insertValues.flatMap { $0 }, on: loop)
                .voided()
        }
    }

    /// Delete all objects in this array.
    func delete(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        Element.query()
            .delete()
            .voided()
    }
}

extension Model {
    /// Whether the model exists in the database already. Currently just whether the id is nil.
    var existsInDatabase: Bool {
        self.id != nil
    }
}
