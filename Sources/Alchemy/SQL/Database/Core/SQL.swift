public struct SQL: Equatable {
    let statement: String
    let bindings: [SQLValue]

    public init(_ statement: String = "", bindings: [SQLValue] = []) {
        self.statement = statement
        self.bindings = bindings
    }
}

extension SQL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.statement = value
        self.bindings = []
    }
}

extension SQL: SQLValueConvertible {
    public var value: SQLValue {
        .string(statement)
    }
}
