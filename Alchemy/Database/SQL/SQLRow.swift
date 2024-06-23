import Collections

/// A row of data returned by an SQL query.
public struct SQLRow: ExpressibleByDictionaryLiteral {
    public let fields: OrderedDictionary<String, SQLValue>

    public init(fields: OrderedDictionary<String, SQLValue>) {
        self.fields = fields
    }

    public init(fields: [(String, SQLValueConvertible)]) {
        let dict = fields.map { ($0, $1.sqlValue) }
        self.init(fields: .init(dict, uniquingKeysWith: { a, _ in a }))
    }

    public init(dictionaryLiteral elements: (String, SQLValueConvertible)...) {
        let dict = elements.map { ($0, $1.sqlValue) }
        self.init(fields: .init(dict, uniquingKeysWith: { a, _ in a }))
    }

    public func contains(_ column: String) -> Bool {
        fields[column] != nil
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
        fields.elements[index].value.sqlValue
    }

    public subscript(_ column: String, default default: SQLValue? = nil) -> SQLValue? {
        fields[column]?.sqlValue ?? `default`
    }
}

extension Array<SQLRow> {
    public func decodeEach<D: Decodable>(_ type: D.Type = D.self,
                                        keyMapping: KeyMapping = .useDefaultKeys,
                                        jsonDecoder: JSONDecoder = JSONDecoder()) throws -> [D] {
        try map { try $0.decode(type, keyMapping: keyMapping, jsonDecoder: jsonDecoder) }
    }
}
