import PostgresNIO

extension PostgresRow: DatabaseRow {
    public var allColumns: [String] {
        self.rowDescription.fields.map { $0.name }
    }
    
    public func getField(columnName: String) throws -> DatabaseField {
        guard let value = self.column(columnName) else {
            throw PostgresError("No column named '\(columnName)' while decoding this row.")
        }
        
        return try value.toDatabaseField(from: columnName)
    }
}
