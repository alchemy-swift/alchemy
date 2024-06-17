/// A MySQL specific Grammar for compiling `Query` to SQL.
struct MySQLGrammar: SQLGrammar {
    func insertReturn(_ table: String, values: [SQLFields]) -> [SQL] {
        values.flatMap {
            [
                insert(table, values: [$0]),
                "SELECT * FROM \(table) WHERE id = LAST_INSERT_ID()"
            ]
        }
    }

    func dropIndex(on table: String, indexName: String) -> SQL {
        "DROP INDEX \(indexName) ON \(table)"
    }

    func columnTypeString(for type: ColumnType) -> String {
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

    func columnConstraintString(for constraint: ColumnConstraint, on column: String, of type: ColumnType) -> String? {
        switch constraint {
        case .notNull:
            return "NOT NULL"
        case .nullable:
            return nil
        case .default(let string):
            return "DEFAULT \(string)"
        case .primaryKey:
            return "PRIMARY KEY (\(column))"
        case .unique:
            return "UNIQUE (\(column))"
        case .foreignKey(let fkColumn, let table, let onDelete, let onUpdate):
            var fkBase = "FOREIGN KEY (\(column)) REFERENCES \(table) (\(fkColumn.inQuotes))"
            if let delete = onDelete { fkBase.append(" ON DELETE \(delete.rawValue)") }
            if let update = onUpdate { fkBase.append(" ON UPDATE \(update.rawValue)") }
            return fkBase
        case .unsigned:
            return "UNSIGNED"
        }
    }

    func jsonLiteral(for jsonString: String) -> String {
        "('\(jsonString)')"
    }

    func random() -> String {
        "RAND()"
    }
}
