import Foundation

public struct SQLField: Equatable {
    public let column: String
    public let value: SQLValue
}

/// A row of data returned by an SQL query.
public struct SQLRow {
    public let fields: [SQLField]
    public let lookupTable: [String: Int]

    public var fieldDictionary: [String: SQLValue] {
        Dictionary(fields.map { ($0.column, $0.value) }, uniquingKeysWith: { current, _ in current })
    }
    
    init(fields: [SQLField]) {
        self.fields = fields
        self.lookupTable = Dictionary(fields.enumerated().map { ($1.column, $0) }, uniquingKeysWith: { current, _ in current })
    }
    
    public func contains(_ column: String) -> Bool {
        lookupTable[column] != nil
    }
    
    public subscript(_ index: Int) -> SQLValue {
        fields[index].value
    }
    
    public subscript(_ column: String) -> SQLValue? {
        guard let index = lookupTable[column] else { return nil }
        return fields[index].value
    }
    
    public func require(_ column: String) throws -> SQLValue {
        try self[column].unwrap(or: DatabaseError.missingColumn(column))
    }
}

extension SQLRow: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, SQLValueConvertible)...) {
        self.init(fields: elements.enumerated().map { SQLField(column: $1.0, value: $1.1.sqlValue) })
    }
}

extension SQLRow {
    /// Decode a `Model` type `D` from this row.
    ///
    /// The default implementation of this function populates the
    /// properties of `D` with the value of the column named the
    /// same as the property.
    ///
    /// - Parameter type: The type to decode from this row.
    public func decode<M: ModelBase>(_ type: M.Type) throws -> M {
        try M(row: self)
    }
    
    public func decode<D: Decodable>(
        _ type: D.Type,
        keyMapping: DatabaseKeyMapping = .useDefaultKeys,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) throws -> D {
        try D(from: SQLRowDecoder(row: self, keyMapping: keyMapping, jsonDecoder: jsonDecoder))
    }
}
