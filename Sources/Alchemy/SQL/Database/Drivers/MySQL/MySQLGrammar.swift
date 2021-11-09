import NIO

/// A MySQL specific Grammar for compiling QueryBuilder statements
/// into SQL strings.
final class MySQLGrammar: Grammar {
    override func compileDropIndex(on table: String, indexName: String) -> SQL {
        SQL("DROP INDEX \(indexName) ON \(table)")
    }
    
    override func typeString(for type: ColumnType) -> String {
        switch type {
        case .bool:
            return "boolean"
        case .date:
            return "datetime"
        case .double:
            return "double"
        case .increments:
            return "serial"
        case .int:
            return "int"
        case .bigInt:
            return "bigint"
        case .json:
            return "json"
        case .string(let length):
            switch length {
            case .unlimited:
                return "text"
            case .limit(let characters):
                return "varchar(\(characters))"
            }
        case .uuid:
            // There isn't a MySQL UUID type; store UUIDs as a 36
            // length varchar.
            return "varchar(36)"
        }
    }
    
    override func jsonLiteral(from jsonString: String) -> String {
        "('\(jsonString)')"
    }
    
    override func allowsUnsigned() -> Bool {
        true
    }
    
    override func insert(_ table: String, values: [[String: SQLValueConvertible]], database: DatabaseDriver, returnItems: Bool) async throws -> [SQLRow] {
        guard returnItems, let database = database as? MySQLDatabase else {
            return try await super.insert(table, values: values, database: database, returnItems: returnItems)
        }
        
        let inserts = try values.map { try compileInsert(table, values: [$0]) }
        var results: [SQLRow] = []
        try await withThrowingTaskGroup(of: [SQLRow].self) { group in
            for insert in inserts {
                group.addTask {
                    async let result = database.runAndReturnLastInsertedItem(insert.statement, table: table, values: insert.bindings)
                    return try await result
                }
            }
            
            for try await model in group {
                results += model
            }
        }
        
        return results
    }
}
