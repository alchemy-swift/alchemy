final class SQLiteGrammar: Grammar {
    override func compileInsertReturn(_ table: String, values: [[String : SQLValueConvertible]]) -> [SQL] {
        return values.flatMap { fields -> [SQL] in
            // If the id is already set, search the database for that. Otherwise
            // assume id is autoincrementing and search for the last rowid.
            let id = fields["id"]
            let idString = id == nil ? "last_insert_rowid()" : "?"
            return [
                compileInsert(table, values: [fields]),
                SQL("select * from \(table) where id = \(idString)", bindings: [id?.sqlValue].compactMap { $0 })
            ]
        }
    }
    
    // No locks are supported with SQLite; the entire database is locked on
    // write anyways.
    override func compileLock(_ lock: SQLQuery.Lock?) -> SQL? {
        return nil
    }
    
    override func columnTypeString(for type: ColumnType) -> String {
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
    
    override func columnConstraintString(for constraint: ColumnConstraint, on column: String, of type: ColumnType) -> String? {
        switch constraint {
        case .primaryKey where type == .increments:
            return nil
        default:
            return super.columnConstraintString(for: constraint, on: column, of: type)
        }
    }
    
    override func jsonLiteral(for jsonString: String) -> String {
        "'\(jsonString)'"
    }

    override func compileAlterTable(_ table: String, dropColumns: [String], addColumns: [CreateColumn], allowConstraints: Bool = true) -> [SQL] {
        // SQLite ALTER TABLE can't drop columns or add constraints. It also only supports adding one column per statement.
        addColumns.map { super.compileAlterTable(table, dropColumns: [], addColumns: [$0], allowConstraints: false) }
            .flatMap { $0 }
    }
}
