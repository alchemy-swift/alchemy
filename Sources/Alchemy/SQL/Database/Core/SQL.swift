public struct SQL: Hashable, ExpressibleByStringLiteral {
    public let statement: String
    public let binds: [SQLValue]

    public var rawSQLString: String {
        binds.reduce(statement) {
            $0.replacingFirstOccurrence(of: "?", with: $1.rawSQLString)
        }
    }

    public init(_ statement: String, binds: [SQLValue]) {
        self.statement = statement
        self.binds = binds
    }

    /// Initialize with a statement and a list of parameters. Some of these
    /// parameters may be SQL expressions themselves and will be inserted
    /// into the provided statement.
    public init(_ statement: String, parameters: [SQLParameterConvertible] = []) {
        let parts = statement.components(separatedBy: "?")
        precondition(parts.count - 1 == parameters.count, "The number of parameters must match the number of '?'s in the statement.")
        var binds: [SQLValue] = []
        var statement = ""
        for (part, parameter) in zip(parts, parameters) {
            statement += part
            switch parameter.sqlParameter {
            case .expression(let sql):
                statement.append(sql.statement)
                binds.append(contentsOf: sql.binds)
            case .value(let value):
                statement.append("?")
                binds.append(value)
            }
        }

        self.init(statement, binds: binds)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}
