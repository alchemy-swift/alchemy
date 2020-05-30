import PostgresNIO

extension PostgresRow: DatabaseRow {
    public var allColumns: [String] {
        self.rowDescription.fields.map { $0.name }
    }
    
    public func getField(columnName: String) throws -> DatabaseField {
        var columnName = columnName
        if columnName == "owner" {
            columnName = "owner_id"
        }
        
        guard let value = self.column(columnName) else {
            
            throw PostgresError("No column named '\(columnName)' was found.")
        }
        
        return try value.toDatabaseField(from: columnName)
    }
}
