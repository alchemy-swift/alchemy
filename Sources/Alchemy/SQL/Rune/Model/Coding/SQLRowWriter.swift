public protocol SQLRowWriter {
    subscript(_ column: String) -> SQLValue? { get set }
    mutating func put<E: Encodable>(json: E, at key: String) throws
}

extension SQLRowWriter {
    public mutating func put(_ value: SQLValue, at key: String) {
        self[key] = value
    }
}
