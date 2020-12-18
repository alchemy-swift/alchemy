/// A row of data returned from a database. Various database packages can use
/// this as an abstraction around their internal row types.
public protocol DatabaseRow {
    /// The `String` names of all columns that have values in this
    /// `DatabaseRow`.
    var allColumns: [String] { get }
    
    /// Get the `DatabaseField` of a column from this row.
    ///
    /// - Parameter column: the column to get the value for.
    /// - Throws: a `DatabaseError` if the column does not exist on this row.
    /// - Returns: the field at `column`.
    func getField(column: String) throws -> DatabaseField
    
    /// Decode a `DatabaseCodable` type `D` from this row.
    ///
    /// The default implementation of this function populates the properties of
    /// `D` with the value of the column named the same as the property.
    ///
    /// - Parameter type: the type to decode from this row.
    func decode<D: DatabaseCodable>(_ type: D.Type) throws -> D
}

extension DatabaseRow {
    public func decode<D: DatabaseCodable>(_ type: D.Type) throws -> D {
        // For each stored coding key, pull out the column name.
        // Will need to write a custom decoder that pulls out of a database row.
        try D(from: DatabaseRowDecoder(row: self, keyMappingStrategy: D.keyMappingStrategy))
    }
}
