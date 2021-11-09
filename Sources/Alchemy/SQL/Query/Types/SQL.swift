public struct SQL: Equatable {
    let query: String
    let bindings: [SQLValue]

    public init(_ query: String = "", bindings: [SQLValue] = []) {
        self.query = query
        self.bindings = bindings
    }
}

extension SQL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.query = value
        self.bindings = []
    }
}

extension SQL: SQLValueConvertible {
    public var value: SQLValue {
        .string(query)
    }
}
