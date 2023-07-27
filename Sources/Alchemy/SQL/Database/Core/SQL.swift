/// A parameterized SQL statement or expression.
public struct SQL: Hashable, ExpressibleByStringLiteral {
    public let statement: String
    public let parameters: [SQLValue]

    public var rawSQLString: String {
        parameters.reduce(statement) {
            $0.replacingFirstOccurrence(of: "?", with: $1.rawSQLString)
        }
    }

    /// Initialize with a statment and a list of parameters.
    public init(_ statement: String, parameters: [SQLValue]) {
        self.statement = statement
        self.parameters = parameters
    }

    /// Initialize with a statement and a list of parameters. Some of these
    /// parameters may be SQL expressions themselves and will be inserted
    /// into the provided statement.
    public init(_ statement: String, parameters: [SQLConvertible] = []) {
        let parts = statement.components(separatedBy: "?")
        precondition(parts.count - 1 == parameters.count, "The number of parameters must match the number of '?'s in the statement.")
        var values: [SQLValue] = []
        var statement = ""
        for (part, parameter) in zip(parts, parameters.map(\.sql)) {
            statement += part
            statement.append(parameter.statement)
            values.append(contentsOf: parameter.parameters)
        }

        self.init(statement, parameters: values)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    public static func value(_ value: SQLValue) -> SQL {
        SQL("?", parameters: [value])
    }
}
