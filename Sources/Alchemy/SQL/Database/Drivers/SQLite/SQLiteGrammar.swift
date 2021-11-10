final class SQLiteGrammar: Grammar {
    override func compileInsertAndReturn(_ table: String, values: [[String : SQLValueConvertible]]) -> [SQL] {
        return values.flatMap { fields -> [SQL] in
            // If the id is already set, search the database for that. Otherwise
            // assume id is autoincrementing and search for the last rowid.
            let id = fields["id"]
            let idString = id == nil ? "last_insert_rowid()" : "?"
            return [
                compileInsert(table, values: [fields]),
                SQL("select * from \(table) where id = \(idString)", bindings: [id?.value].compactMap { $0 })
            ]
        }
    }
    
    // No locks are supported with SQLite; the entire database is locked on
    // write anyways.
    override func compileLock(_ lock: Query.Lock?) -> SQL? {
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
}
