public struct SQLRowWriter {
    public internal(set) var fields: SQLFields
    let keyMapping: KeyMapping
    let jsonEncoder: JSONEncoder

    public init(keyMapping: KeyMapping = .useDefaultKeys, jsonEncoder: JSONEncoder = JSONEncoder()) {
        self.fields = [:]
        self.keyMapping = keyMapping
        self.jsonEncoder = jsonEncoder
    }

    public mutating func put(json: some Encodable, at key: String) throws {
        let jsonData = try jsonEncoder.encode(json)
        let bytes = ByteBuffer(data: jsonData)
        self[key] = .value(.json(bytes))
    }

    public mutating func put(sql: SQLConvertible, at key: String) {
        self[key] = sql
    }

    public subscript(column: String) -> SQLConvertible? {
        get { fields[column] }
        set { fields[keyMapping.encode(column)] = newValue ?? .null }
    }
}

extension SQLRowWriter {
    public mutating func put(_ value: ModelProperty, at key: String) throws {
        try value.store(key: key, on: &self)
    }

    public mutating func put(_ value: some Encodable, at key: String) throws {
        if let value = value as? ModelProperty {
            try put(value, at: key)
        } else {
            try put(json: value, at: key)
        }
    }

    public mutating func put<F: FixedWidthInteger>(_ int: F, at key: String) {
        self[key] = Int(int)
    }
}
