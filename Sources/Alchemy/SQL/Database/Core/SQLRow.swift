import Foundation

struct SQLField {
    let index: Int
    let column: String
    let value: SQLValue
}

struct SQLRow2 {
    let fields: [SQLField]
    let lookupTable: [String: Int]
    
    init(fields: [SQLField]) {
        self.fields = fields
        self.lookupTable = Dictionary(fields.enumerated().map { ($1.column, $0) }, uniquingKeysWith: { current, _ in current })
    }
    
    func contains(_ column: String) -> Bool {
        lookupTable[column] != nil
    }
    
    subscript(_ index: Int) -> SQLValue {
        fields[index].value
    }
    
    subscript(_ column: String) -> SQLValue? {
        guard let index = lookupTable[column] else { return nil }
        return fields[index].value
    }
}

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
    
    func decode<D: Model>(_ type: D.Type) throws -> D
}

extension SQLRow {
    /// Decode a `Model` type `D` from this row.
    ///
    /// The default implementation of this function populates the
    /// properties of `D` with the value of the column named the
    /// same as the property.
    ///
    /// - Parameter type: The type to decode from this row.
    public func decode<M: Model>(_ type: M.Type) throws -> M {
        try M(from: SQLRowDecoder(row: self, keyMapping: M.keyMapping, jsonDecoder: M.jsonDecoder))
    }
    
    public func decode<D: Decodable>(
        _ type: D.Type,
        keyMapping: DatabaseKeyMapping = .useDefaultKeys,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) throws -> D {
        try D(from: SQLRowDecoder(row: self, keyMapping: keyMapping, jsonDecoder: jsonDecoder))
    }
    
    /// Subscript for convenience access.
    public subscript(column: String) -> SQLValue? {
        columns.contains(column) ? try? get(column) : nil
    }
}
