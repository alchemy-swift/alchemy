extension Query {
    /// The type of the join clause.
    public enum JoinType: String {
        /// INNER JOIN.
        case inner
        /// OUTER JOIN.
        case outer
        /// LEFT JOIN.
        case left
        /// RIGHT JOIN.
        case right
        /// CROSS JOIN.
        case cross
    }

    /// A JOIN query builder.
    public final class Join: Query {
        /// The type of the join to perform.
        var type: JoinType
        /// The table to join to.
        let joinTable: String
        /// The join conditions
        var joinWheres: [Query.Where] = []
        
        /// Create a join builder with a query, type, and table.
        ///
        /// - Parameters:
        ///   - database: The database the join table is on.
        ///   - type: The type of join this is.
        ///   - joinTable: The name of the table to join to.
        init(database: DatabaseProvider, table: String, type: JoinType, joinTable: String) {
            self.type = type
            self.joinTable = joinTable
            super.init(database: database, table: table)
        }
        
        func on(first: String, op: Operator, second: String, boolean: WhereBoolean = .and) -> Join {
            joinWheres.append(Where(type: .column(first: first, op: op, second: second), boolean: boolean))
            return self
        }

        func orOn(first: String, op: Operator, second: String) -> Join {
            on(first: first, op: op, second: second, boolean: .or)
        }
        
        override func isEqual(to other: Query) -> Bool {
            guard let other = other as? Join else {
                return false
            }
            
            return super.isEqual(to: other) &&
                type == other.type &&
                joinTable == other.joinTable &&
                joinWheres == other.joinWheres
        }
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
    public func join(table: String, first: String, op: Operator = .equals, second: String, type: JoinType = .inner) -> Self {
        joins.append(
            Join(database: database, table: self.table, type: type, joinTable: table)
                .on(first: first, op: op, second: second)
        )
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
    public func join(table: String, type: JoinType = .inner, conditions: (Join) -> Join) -> Self {
        joins.append(conditions(Join(database: database, table: self.table, type: type, joinTable: table)))
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
    public func leftJoin(table: String, first: String, op: Operator = .equals, second: String) -> Self {
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
    public func rightJoin(table: String, first: String, op: Operator = .equals, second: String) -> Self {
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
    public func crossJoin(table: String, first: String, op: Operator = .equals, second: String) -> Self {
        join(table: table, first: first, op: op, second: second, type: .cross)
    }
}
