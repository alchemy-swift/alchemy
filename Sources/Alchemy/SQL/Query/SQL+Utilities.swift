extension Array where Element: SQLConvertible {
    public func joined() -> SQL {
        let statements = map(\.sql)
        return SQL(statements.map(\.statement).joined(separator: " "), bindings: statements.flatMap(\.bindings))
    }
}

extension SQL {
    func droppingLeadingBoolean() -> SQL {
        SQL(statement.droppingPrefix("and ").droppingPrefix("or "), bindings: bindings)
    }
}
