/// A parameterized SQL statement or expression.
public struct SQL: Hashable, ExpressibleByStringInterpolation {
    public let statement: String
    public let parameters: [SQLValue]

    public var rawSQLString: String {
        parameters.reduce(statement) {
            $0.replacingFirstOccurrence(of: "?", with: $1.rawSQLString)
        }
    }

    /// Initialize with a statement and a list of parameters.
    public init(_ statement: String, values: [SQLValue]) {
        self.statement = statement
        self.parameters = values
    }

    /// Initialize with a statement and a list of parameters. Some of these
    /// parameters may be SQL expressions themselves and will be inserted
    /// into the provided statement.
    public init(_ statement: String, parameters: [SQLConvertible] = []) {
        // 0. Escape double question marks.
        let questionmark = "__questionmark"
        let escapedStatement = statement.replacingOccurrences(of: "??", with: questionmark)

        // 1. Replace question marks with corresponding parameter statement.
        let parts = escapedStatement.components(separatedBy: "?")
        precondition(parts.count - 1 == parameters.count, "The number of parameters must match the number of '?'s in the statement.")
        var values: [SQLValue] = []
        var statement = ""
        for (index, parameter) in parameters.enumerated() {
            let sql = parameter.sql
            statement += parts[index]
            statement += sql.statement
            values += sql.parameters
        }

        statement += parts[parts.count - 1]

        // 2. Replace escaped question marks.
        statement = statement.replacingOccurrences(of: questionmark, with: "?")
        self.init(statement, values: values)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value, values: [])
    }

    public static func value(_ value: SQLValue) -> SQL {
        SQL("?", values: [value])
    }
}
