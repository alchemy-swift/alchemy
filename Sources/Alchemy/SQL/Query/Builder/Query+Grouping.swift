extension Query {
    /// Group returned data by a given column.
    ///
    /// - Parameter group: The table column to group data on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func groupBy(_ group: String) -> Self {
        self.groups.append(group)
        return self
    }
    
    /// Add a having clause to filter results from aggregate
    /// functions.
    ///
    /// - Parameter clause: A `WhereValue` clause matching a column to a
    ///   value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func having(_ clause: WhereValue) -> Self {
        self.havings.append(clause)
        return self
    }

    /// An alias for `having(_ clause:) ` that appends an or clause
    /// instead of an and clause.
    ///
    /// - Parameter clause: A `WhereValue` clause matching a column to a
    ///   value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orHaving(_ clause: WhereValue) -> Self {
        var clause = clause
        clause.boolean = .or
        return self.having(clause)
    }

    /// Add a having clause to filter results from aggregate functions
    /// that matches a given key to a provided value.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - value: The value that the column should  match.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`).
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func having(key: String, op: Operator, value: SQLValueConvertible, boolean: WhereBoolean = .and) -> Self {
        return self.having(WhereValue(
            key: key,
            op: op,
            value: value.value,
            boolean: boolean)
        )
    }
}
