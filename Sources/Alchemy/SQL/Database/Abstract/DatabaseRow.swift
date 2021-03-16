/// A row of data returned from a database. Various database packages
/// can use this as an abstraction around their internal row types.
public protocol DatabaseRow {
    /// The `String` names of all columns that have values in this
    /// `DatabaseRow`.
    var allColumns: Set<String> { get }
    
    /// Get the `DatabaseField` of a column from this row.
    ///
    /// - Parameter column: The column to get the value for.
    /// - Throws: A `DatabaseError` if the column does not exist on
    ///   this row.
    /// - Returns: The field at `column`.
    func getField(column: String) throws -> DatabaseField
    
    /// Decode a `Model` type `D` from this row.
    ///
    /// The default implementation of this function populates the
    /// properties of `D` with the value of the column named the
    /// same as the property.
    ///
    /// - Parameter type: The type to decode from this row.
    func decode<D: Model>(_ type: D.Type) throws -> D
}

extension DatabaseRow {
    public func decode<M: Model>(_ type: M.Type) throws -> M {
        // For each stored coding key, pull out the column name. Will
        // need to write a custom decoder that pulls out of a database
        // row.
        try M(from: DatabaseRowDecoder<M>(row: self))
    }
}
