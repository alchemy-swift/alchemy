import Foundation

/// A row of data returned by an SQL query.
public struct SQLRow: ExpressibleByDictionaryLiteral {
    public let fields: [(column: String, value: SQLValue)]
    private let lookupTable: [String: Int]

    public var fieldDictionary: [String: SQLValue] {
        lookupTable.mapValues { fields[$0].value }
    }
    
    public init(fields: [(column: String, value: SQLValue)]) {
        self.fields = fields
        self.lookupTable = Dictionary(fields.enumerated().map { ($1.column, $0) })
    }

    public init(fields: [(column: String, value: SQLValueConvertible)]) {
        self.init(fields: fields.map { ($0, $1.sqlValue) })
    }

    public init(dictionaryLiteral elements: (String, SQLValueConvertible)...) {
        self.init(fields: elements)
    }

    public func contains(_ column: String) -> Bool {
        lookupTable[column] != nil
    }

    public func require(_ column: String) throws -> SQLValue {
        guard let value = self[column] else {
            throw DatabaseError("Missing column named `\(column)`.")
        }

        return value
    }

    public func decode<D: Decodable>(_ type: D.Type = D.self,
                                     keyMapping: KeyMapping = .useDefaultKeys,
                                     jsonDecoder: JSONDecoder = JSONDecoder()) throws -> D {
        try D(from: SQLRowDecoder(row: self, keyMapping: keyMapping, jsonDecoder: jsonDecoder))
    }

    public subscript(_ index: Int) -> SQLValue {
        fields[index].value
    }

    public subscript(_ column: String) -> SQLValue? {
        guard let index = lookupTable[column] else { return nil }
        return fields[index].value
    }
}

extension Array<SQLRow> {
    public func decodeEach<D: Decodable>(_ type: D.Type,
                                        keyMapping: KeyMapping = .useDefaultKeys,
                                        jsonDecoder: JSONDecoder = JSONDecoder()) throws -> [D] {
        try map { try $0.decode(type, keyMapping: keyMapping, jsonDecoder: jsonDecoder) }
    }
}
