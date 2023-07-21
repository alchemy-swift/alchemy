/// A JOIN query builder.
public struct SQLJoin: Equatable {
    /// The type of the join clause.
    public enum JoinType: String {
        /// INNER JOIN.
        case inner = "INNER"
        /// OUTER JOIN.
        case outer = "OUTER"
        /// LEFT JOIN.
        case left = "LEFT"
        /// RIGHT JOIN.
        case right = "RIGHT"
        /// CROSS JOIN.
        case cross = "CROSS"
    }

    /// The type of the join to perform.
    var type: JoinType
    /// The table to join to.
    let table: String
    /// The join conditions
    var wheres: [SQLWhere] = []

    /// Create a join builder with a query, type, and table.
    ///
    /// - Parameters:
    ///   - type: The type of join this is.
    ///   - joinTable: The name of the table to join to.
    init(type: JoinType, joinTable: String) {
        self.type = type
        self.table = joinTable
    }

    func on(first: String, op: SQLWhere.Operator, second: String, boolean: SQLWhere.Boolean = .and) -> Self {
        var join = self
        join.wheres.append(SQLWhere(type: .column(first: first, op: op, second: second), boolean: boolean))
        return join
    }

    func orOn(first: String, op: SQLWhere.Operator, second: String) -> SQLJoin {
        on(first: first, op: op, second: second, boolean: .or)
    }
}

extension Query {

    func join(_ join: SQLJoin) -> Self {
        query.joins.append(join)
        return self
    }

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
    public func join(table: String, first: String, op: SQLWhere.Operator = .equals, second: String, type: SQLJoin.JoinType = .inner) -> Self {
        let join = SQLJoin(type: type, joinTable: table)
        query.joins.append(join.on(first: first, op: op, second: second))
        return self
    }
    
    /// Joins data from a separate table into the current query, using the given
    /// conditions closure.
    ///
    /// - Parameters:
    ///   - table: The table to join with.
    ///   - type: The type of join. Defaults to `.inner`
    ///   - conditions: A closure that sets the conditions on the join using.
    /// - Returns: This query builder.
    public func join(table: String, type: SQLJoin.JoinType = .inner, conditions: (SQLJoin) -> SQLJoin) -> Self {
        query.joins.append(conditions(SQLJoin(type: type, joinTable: table)))
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
    public func leftJoin(table: String, first: String, op: SQLWhere.Operator = .equals, second: String) -> Self {
        join(table: table, first: first, op: op, second: second, type: .left)
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
    public func rightJoin(table: String, first: String, op: SQLWhere.Operator = .equals, second: String) -> Self {
        join(table: table, first: first, op: op, second: second, type: .right)
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
    public func crossJoin(table: String, first: String, op: SQLWhere.Operator = .equals, second: String) -> Self {
        join(table: table, first: first, op: op, second: second, type: .cross)
    }
}
