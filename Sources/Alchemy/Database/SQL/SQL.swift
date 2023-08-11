/// A parameterized SQL statement or expression.
public struct SQL: Hashable, ExpressibleByStringInterpolation, CustomStringConvertible {
    public let statement: String
    public let parameters: [SQLValue]

    public var description: String {
        let binds = parameters.isEmpty ? "" : " \(parameters)"
        return "\(statement);\(binds)"
    }

    public var rawSQLString: String {
        parameters.reduce(statement) {
            $0.replacingFirstOccurrence(of: "?", with: $1.rawSQLString)
        }
    }

    /// Initialize with a statement and a list of SQLValues.
    public init(_ statement: String, parameters: [SQLValue]) {
        self.statement = statement
        self.parameters = parameters
    }

    /// Initialize with a statement and a list of SQLValueConvertibles.
    public init(_ statement: String, parameters: [SQLValueConvertible]) {
        self.statement = statement
        self.parameters = parameters.map(\.sqlValue)
    }

    /// Initialize with a statement and a list of input parameters. Some of the
    /// inputs may be SQL expressions themselves (such as `NOW()`) and will
    /// replace '?'s in the provided statement.
    public init(_ statement: String, input: [SQLConvertible] = []) {
        // 0. Escape double question marks.
        let questionmark = "___questionmark"
        let escapedStatement = statement.replacingOccurrences(of: "??", with: questionmark)

        // 1. Replace question marks with corresponding parameter statement.
        let parts = escapedStatement.components(separatedBy: "?")
        precondition(parts.count - 1 == input.count, "The number of parameters must match the number of '?'s in the statement.")
        var values: [SQLValue] = []
        var statement = ""
        for (index, input) in input.enumerated() {
            let sql = input.sql
            var sqlStatement = sql.statement
            if sqlStatement.hasPrefix("SELECT") {
                sqlStatement = "(\(sqlStatement))"
            }

            statement += parts[index]
            statement += sqlStatement
            values += sql.parameters
        }

        statement += parts[parts.count - 1]

        // 2. Replace escaped question marks.
        statement = statement.replacingOccurrences(of: questionmark, with: "?")
        self.init(statement, parameters: values)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.statement = value
        self.parameters = []
    }

    public static func value(_ value: SQLValue) -> SQL {
        SQL("?", parameters: [value])
    }
}

extension Array where Element == SQL {
    public func joined() -> SQL {
        SQL(map(\.statement).joined(separator: " "), parameters: flatMap(\.parameters))
    }
}
