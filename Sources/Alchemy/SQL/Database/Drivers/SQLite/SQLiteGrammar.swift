struct SQLiteGrammar: SQLGrammar {
    func insertReturn(_ table: String, values: [[String : SQLConvertible]]) -> [SQL] {
        return values.flatMap { fields -> [SQL] in
            // If the id is already set, search the database for that. Otherwise
            // assume id is autoincrementing and search for the last rowid.
            let id = fields["id"]
            let idString = id == nil ? "last_insert_rowid()" : "?"
            return [
                insert(table, values: [fields]),
                SQL("SELECT * FROM \(table) WHERE id = \(idString)", parameters: [id].compactMap { $0 })
            ]
        }
    }

    func compileLock(_ lock: SQLLock?) -> SQL? {
        // No locks are supported with SQLite; the entire database is locked on
        // write anyways.
        return nil
    }

    func columnTypeString(for type: ColumnType) -> String {
        switch type {
        case .bool:
            return "integer"
        case .date:
            return "datetime"
        case .double:
            return "double"
        case .increments:
            return "integer PRIMARY KEY AUTOINCREMENT"
        case .int:
            return "integer"
        case .bigInt:
            return "integer"
        case .json:
            return "text"
        case .string:
            return "text"
        case .uuid:
            return "text"
        }
    }

    public func columnConstraintString(for constraint: ColumnConstraint, on column: String, of type: ColumnType) -> String? {
        switch constraint {
        case .notNull:
            return "NOT NULL"
        case .default(let string):
            return "DEFAULT \(string)"
        case .primaryKey:
            guard type != .increments else { return nil }
            return "PRIMARY KEY (\(column))"
        case .unique:
            return "UNIQUE (\(column))"
        case .foreignKey(let fkColumn, let table, let onDelete, let onUpdate):
            var fkBase = "FOREIGN KEY (\(column)) REFERENCES \(table) (\(fkColumn.inQuotes))"
            if let delete = onDelete { fkBase.append(" ON DELETE \(delete.rawValue)") }
            if let update = onUpdate { fkBase.append(" ON UPDATE \(update.rawValue)") }
            return fkBase
        case .unsigned:
            return nil
        }
    }

    func jsonLiteral(for jsonString: String) -> String {
        "'\(jsonString)'"
    }

    func compileAlterTable(_ table: String, dropColumns: [String], addColumns: [CreateColumn]) -> [SQL] {
        guard !addColumns.isEmpty else { return [] }

        // SQLite ALTER TABLE can't drop columns or add constraints. It also only supports adding one column per statement.
        let statements = addColumns.map(createColumnString)
            .map { "ADD COLUMN \($0.definition)" }
            .joined(separator: ",\n    ")

        return [
            """
            ALTER TABLE \(table)
                \(statements)
            """
        ]
    }
}
