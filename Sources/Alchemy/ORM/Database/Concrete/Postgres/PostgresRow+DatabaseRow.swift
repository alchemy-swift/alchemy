import PostgresNIO

extension PostgresRow: DatabaseRow {
    public func getField(columnName: String) throws -> DatabaseField {
        guard let value = self.column(columnName) else {
            throw PostgresError(message: "No column named '\(columnName)' was found.")
        }
        
        return try value.toDatabaseField(from: columnName)
    }
    
    public func decode<D>(_ type: D.Type) -> D where D : DatabaseDecodable {
        fatalError()
    }
}
