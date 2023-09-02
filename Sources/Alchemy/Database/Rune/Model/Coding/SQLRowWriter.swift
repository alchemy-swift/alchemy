public protocol SQLRowWriter {
    subscript(_ column: String) -> SQLConvertible? { get set }
    mutating func put<E: Encodable>(json: E, at key: String) throws
}

extension SQLRowWriter {
    public mutating func put(_ value: SQLConvertible, at key: String) {
        self[key] = value
    }

    public mutating func put<F: FixedWidthInteger>(_ int: F, at key: String) {
        self[key] = Int(int)
    }
}
