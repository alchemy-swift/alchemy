extension Query {
    /// Join data from a separate table into the current query data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    ///   - type: The `JoinType` of the sql join. Defaults to
    ///     `.inner`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func join(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String,
        type: JoinType = .inner
    ) -> Self {
        let join = JoinClause(database: self.database, type: type, table: table)
            .on(first: first, op: op, second: second)
        if joins == nil {
            joins = [join]
        }
        else {
            joins?.append(join)
        }
        return self
    }

    /// Left join data from a separate table into the current query
    /// data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func leftJoin(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String
    ) -> Self {
        self.join(
            table: table,
            first: first,
            op: op,
            second: second,
            type: .left
        )
    }

    /// Right join data from a separate table into the current query
    /// data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func rightJoin(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String
    ) -> Self {
        self.join(
            table: table,
            first: first,
            op: op,
            second: second,
            type: .right
        )
    }

    /// Cross join data from a separate table into the current query
    /// data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func crossJoin(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String
    ) -> Self {
        self.join(
            table: table,
            first: first,
            op: op,
            second: second,
            type: .cross
        )
    }
}
