final class SQLiteGrammar: Grammar {
    override var isSQLite: Bool {
        true
    }
    
    override func insert(_ table: String, values: [OrderedDictionary<String, SQLValueConvertible>], database: DatabaseDriver, returnItems: Bool) async throws -> [SQLRow] {
        return try await database.transaction { conn in
            let sql = try super.compileInsert(table, values: values)
            _ = try await conn.runRawQuery(sql.statement, values: sql.bindings)
            return try await conn.runRawQuery("select * from \(table) where id = last_insert_rowid()", values: [])
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
            // There isn't a MySQL UUID type; store UUIDs as a 36
            // length varchar.
            return "text"
        }
    }
}
