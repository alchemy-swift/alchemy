public protocol SQLRowReader {
    var row: SQLRow { get }
    func require(_ key: String) throws -> SQLValue
    func requireJSON<D: Decodable>(_ key: String) throws -> D
    func contains(_ column: String) -> Bool
    subscript(_ index: Int) -> SQLValue { get }
    subscript(_ column: String) -> SQLValue? { get }
}

struct GenericRowReader: SQLRowReader {
    let row: SQLRow
    let keyMapping: KeyMapping
    let jsonDecoder: JSONDecoder

    func requireJSON<D: Decodable>(_ key: String) throws -> D {
        let key = keyMapping.encode(key)
        return try jsonDecoder.decode(D.self, from: row.require(key).json(key))
    }

    func require(_ key: String) throws -> SQLValue {
        try row.require(keyMapping.encode(key))
    }

    func contains(_ column: String) -> Bool {
        row[keyMapping.encode(column)] != nil
    }

    subscript(_ index: Int) -> SQLValue {
        row[index]
    }

    subscript(_ column: String) -> SQLValue? {
        row[keyMapping.encode(column)]
    }
}
