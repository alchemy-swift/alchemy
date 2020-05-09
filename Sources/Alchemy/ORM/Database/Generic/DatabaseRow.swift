/// A row of data returned from a database.
public protocol DatabaseRow {
    var allColumns: [String] { get }
    
    /// Get a specific named field on a Database.
    func getField(columnName: String) throws -> DatabaseField
    func decode<D: DatabaseDecodable>(_ type: D.Type) -> D
}

extension DatabaseRow {
    func decode<D: DatabaseDecodable>(_ type: D.Type) -> D {
        /// For each stored coding key, pull out the column name.
        /// Will need to write a custom decoder that pulls out of a database row.
        fatalError()
    }
}
