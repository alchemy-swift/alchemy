import Foundation

public struct SQLRowReader {
    public let row: SQLRow
    public let keyMapping: KeyMapping
    public let jsonDecoder: JSONDecoder

    public init(row: SQLRow, keyMapping: KeyMapping = .useDefaultKeys, jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.row = row
        self.keyMapping = keyMapping
        self.jsonDecoder = jsonDecoder
    }

    public func require(_ key: String) throws -> SQLValue {
        try row.require(keyMapping.encode(key))
    }

    public func requireJSON<D: Decodable>(_ key: String) throws -> D {
        let key = keyMapping.encode(key)
        if let type = D.self as? AnyOptional.Type, row[key, default: .null] == .null {
            return type.nilValue as! D
        } else {
            return try jsonDecoder.decode(D.self, from: row.require(key).json(key))
        }
    }

    public func require<D: Decodable>(_ type: D.Type, at key: String) throws -> D {
        if let type = type as? ModelProperty.Type {
            return try type.init(key: key, on: self) as! D
        } else {
            return try requireJSON(key)
        }
    }

    public func require<M: Model, D: Decodable>(_ keyPath: KeyPath<M, D>, at key: String) throws -> D {
        try require(D.self, at: key)
    }

    public func contains(_ column: String) -> Bool {
        row[keyMapping.encode(column)] != nil
    }

    public subscript(_ index: Int) -> SQLValue {
        row[index]
    }

    public subscript(_ column: String) -> SQLValue? {
        row[keyMapping.encode(column)]
    }
}
