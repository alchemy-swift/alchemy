extension Query {
    /// Group returned data by a given column.
    public func groupBy(_ column: String) -> Self {
        groups.append(column)
        return self
    }
    
    /// Add a having clause to filter results from aggregate functions.
    public func having(_ clause: SQLWhere.Clause) -> Self {
        havings.append(.and(clause))
        return self
    }

    /// Add an or having clause to filter results from aggregate functions.
    public func orHaving(_ clause: SQLWhere.Clause) -> Self {
        havings.append(.or(clause))
        return self
    }

    public func havingRaw(_ sql: String, parameters: [SQLValue]) -> Self {
        having(.raw(SQL(sql, parameters: parameters)))
    }

    public func orHavingRaw(_ sql: String, parameters: [SQLValue]) -> Self {
        orHaving(.raw(SQL(sql, parameters: parameters)))
    }

    /// Add a having clause to filter results from aggregate functions that
    /// matches a given key to a provided value.
    public func having(_ column: String, _ op: SQLWhere.Operator, _ value: SQLConvertible) -> Self {
        having(.value(column: column, op: op, value: value.sql))
    }

    public func orHaving(_ column: String, _ op: SQLWhere.Operator, _ value: SQLConvertible) -> Self {
        orHaving(.value(column: column, op: op, value: value.sql))
    }
}
