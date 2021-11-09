final class SQLiteGrammar: Grammar {
    override func compileInsertAndReturn(_ table: String, values: [[String : SQLValueConvertible]]) -> [SQL] {
        return values.flatMap {
            return [
                compileInsert(table, values: [$0]),
                SQL("select * from \(table) where id = last_insert_rowid()")
            ]
        }
    }
    
    override func typeString(for type: ColumnType) -> String {
        switch type {
        case .bool:
            return "integer"
        case .date:
            return "text"
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
    
    override func sqlString(for constraint: ColumnConstraint, on column: String, of type: ColumnType) -> String? {
        switch constraint {
        case .primaryKey where type == .increments:
            return nil
        default:
            return super.sqlString(for: constraint, on: column, of: type)
        }
    }
}
