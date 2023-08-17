extension Query {
    /// Group returned data by a given column.
    ///
    /// - Parameter group: The table column to group data on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func groupBy(_ column: String) -> Self {
        groups.append(column)
        return self
    }
    
    /// Add a having clause to filter results from aggregate
    /// functions.
    ///
    /// - Parameter clause: A `WhereValue` clause matching a column to a
    ///   value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func having(_ clause: SQLWhere.Clause) -> Self {
        havings.append(.and(clause))
        return self
    }

    /// An alias for `having(_ clause:) ` that appends an or clause
    /// instead of an and clause.
    ///
    /// - Parameter clause: A `WhereValue` clause matching a column to a
    ///   value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
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

    /// Add a having clause to filter results from aggregate functions
    /// that matches a given key to a provided value.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - value: The value that the column should  match.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func having(_ column: String, _ op: SQLWhere.Clause.Operator, _ value: SQLConvertible) -> Self {
        having(.value(column: column, op: op, value: value.sql))
    }

    public func orHaving(_ column: String, _ op: SQLWhere.Clause.Operator, _ value: SQLConvertible) -> Self {
        orHaving(.value(column: column, op: op, value: value.sql))
    }
}
