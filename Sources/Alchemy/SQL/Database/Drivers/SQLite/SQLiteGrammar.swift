final class SQLiteGrammar: Grammar {
    override var isSQLite: Bool {
        true
    }
    
    override func insert(_ values: [OrderedDictionary<String, SQLValueConvertible>], query: Query, returnItems: Bool) async throws -> [SQLRow] {
        return try await query.database.transaction { conn in
            let sql = try super.compileInsert(query, values: values)
            let initial = try await conn.runRawQuery(sql.statement, values: sql.bindings)
            if let from = query.from {
                return try await conn.runRawQuery("select * from \(from) where id = last_insert_rowid()", values: [])
            } else {
                return initial
            }
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
