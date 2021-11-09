extension Array where Element: SQLConvertible {
    public func joined() -> SQL {
        map(\.sql).reduce(SQL(), +)
    }
}

extension SQL {
    public static func + (lhs: SQL, rhs: SQL) -> SQL {
        SQL("\(lhs.sqlString) \(rhs.sqlString)", bindings: lhs.bindings + rhs.bindings)
    }
    
    func droppingLeadingBoolean() -> SQL {
        SQL(statement.droppingPrefix("and ").droppingPrefix("or "), bindings: bindings)
    }
}
