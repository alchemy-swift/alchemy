public protocol SQLRowWriter {
    subscript(_ column: String) -> SQLParameter? { get set }
    mutating func put<E: Encodable>(json: E, at key: String) throws
}

extension SQLRowWriter {
    public mutating func put(_ value: SQLParameter, at key: String) {
        self[key] = value
    }

    public mutating func put(_ string: String, at key: String) {
        self[key] = .value(.string(string))
    }

    public mutating func put(_ bool: Bool, at key: String) {
        self[key] = .value(.bool(bool))
    }

    public mutating func put<F: FixedWidthInteger>(_ int: F, at key: String) {
        self[key] = .value(.int(Int(int)))
    }

    public mutating func put(_ float: Float, at key: String) {
        self[key] = .value(.double(Double(float)))
    }

    public mutating func put(_ double: Double, at key: String) {
        self[key] = .value(.double(double))
    }

    public mutating func put(_ date: Date, at key: String) {
        self[key] = .value(.date(date))
    }

    public mutating func put(_ data: Data, at key: String) {
        self[key] = .value(.data(data))
    }

    public mutating func put(_ uuid: UUID, at key: String) {
        self[key] = .value(.uuid(uuid))
    }
}
