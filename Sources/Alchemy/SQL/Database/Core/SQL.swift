public struct SQL: Equatable, ExpressibleByStringLiteral, SQLValueConvertible {
    public let statement: String
    public let bindings: [SQLValue]

    public var sqlValue: SQLValue {
        .string(statement)
    }

    public init(_ statement: String, bindings: [SQLValue] = []) {
        self.statement = statement
        self.bindings = bindings
    }

    public init(stringLiteral value: StringLiteralType) {
        self.statement = value
        self.bindings = []
    }
}
