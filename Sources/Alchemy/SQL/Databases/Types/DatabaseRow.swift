/// A row of data returned from a database.
public protocol DatabaseRow {
    var allColumns: [String] { get }
    
    /// Get a specific named field on a Database.
    func getField(columnName: String) throws -> DatabaseField
    func decode<D: DatabaseCodable>(_ type: D.Type) throws -> D
}

extension DatabaseRow {
    public func decode<D: DatabaseCodable>(_ type: D.Type) throws -> D {
        /// For each stored coding key, pull out the column name.
        /// Will need to write a custom decoder that pulls out of a database row.
        try D(from: DatabaseRowDecoder(row: self, keyMappingStrategy: D.keyMappingStrategy))
    }
}
