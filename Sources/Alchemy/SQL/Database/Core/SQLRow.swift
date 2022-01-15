import Foundation

/// A row of data returned from a database. Various database packages
/// can use this as an abstraction around their internal row types.
public protocol SQLRow {
    /// The `String` names of all columns that have values in this row.
    var columns: Set<String> { get }
    
    /// Get the `SQLValue` of a column from this row.
    ///
    /// - Parameter column: The column to get the value for.
    /// - Throws: A `DatabaseError` if the column does not exist on
    ///   this row.
    /// - Returns: The value at `column`.
    func get(_ column: String) throws -> SQLValue
    
    /// Decode a `Model` type `D` from this row.
    ///
    /// The default implementation of this function populates the
    /// properties of `D` with the value of the column named the
    /// same as the property.
    ///
    /// - Parameter type: The type to decode from this row.
    func decode<D: Model>(_ type: D.Type) throws -> D
}

extension SQLRow {
    public func decode<D: Decodable>(
        _ type: D.Type,
        keyMapping: DatabaseKeyMapping = .useDefaultKeys,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) throws -> D {
        try D(from: SQLRowDecoder(row: self, keyMapping: keyMapping, jsonDecoder: jsonDecoder))
    }
    
    public func decode<M: Model>(_ type: M.Type) throws -> M {
        try M(from: SQLRowDecoder(row: self, keyMapping: M.keyMapping, jsonDecoder: M.jsonDecoder))
    }
    
    /// Subscript for convenience access.
    public subscript(column: String) -> SQLValue? {
        columns.contains(column) ? try? get(column) : nil
    }
}
