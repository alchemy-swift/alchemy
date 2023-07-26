public struct SQL: Hashable, Equatable, ExpressibleByStringLiteral, SQLValueConvertible {
    public let statement: String
    public let bindings: [SQLValue]

    public var sqlValue: SQLValue {
        .raw(self)
    }

    public var rawSQLString: String {
        bindings.reduce(statement) {
            $0.replacingFirstOccurrence(of: "?", with: $1.rawSQLString)
        }
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
