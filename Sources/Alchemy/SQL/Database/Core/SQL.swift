public struct SQL: Hashable, Equatable, ExpressibleByStringLiteral {
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

    public init(_ statement: String, parameters: [SQLParameterConvertible] = []) {
        let parts = statement.components(separatedBy: "?")
        precondition(parts.count - 1 == parameters.count, "The number of parameters must match the number of '?'s in the statement.")
        var binds: [SQLValue] = []
        var statement = ""
        for (index, part) in parts.enumerated() {
            statement += part
            switch parameters[index].sqlParameter {
            case .expression(let sql):
                statement.append(sql.statement)
                binds.append(contentsOf: sql.binds)
            case .value(let value):
                statement.append("?")
                binds.append(value)
            }
        }

        self.statement = statement
        self.binds = binds
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}
