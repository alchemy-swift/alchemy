public final class SQLRowWriter {
    public internal(set) var fields: SQLFields
    let keyMapping: KeyMapping
    let jsonEncoder: JSONEncoder

    public init(keyMapping: KeyMapping, jsonEncoder: JSONEncoder) {
        self.fields = [:]
        self.keyMapping = keyMapping
        self.jsonEncoder = jsonEncoder
    }

    public func put(json: some Encodable, at key: String) throws {
        let jsonData = try jsonEncoder.encode(json)
        let bytes = ByteBuffer(data: jsonData)
        self[key] = .value(.json(bytes))
    }

    public func put(sql: SQLConvertible, at key: String) {
        self[key] = sql
    }

    public subscript(column: String) -> SQLConvertible? {
        get { fields[column] }
        set { fields[keyMapping.encode(column)] = newValue ?? .null }
    }
}

extension SQLRowWriter {
    public func put(_ value: ModelProperty, at key: String) throws {

    }

    public func put(_ value: some Encodable, at key: String) throws {
        if let value = value as? ModelProperty {
            try value.store(key: key, on: self)
        } else {
            try put(json: value, at: key)
        }
    }

    public func put<F: FixedWidthInteger>(_ int: F, at key: String) {
        self[key] = Int(int)
    }
}
