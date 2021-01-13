import Foundation

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
public final class JoinClause: Query {
    /// The type of the join to perform.
    public let type: JoinType
    /// The table to join to.
    public let table: String
    
    /// Create a join builder with a query, type, and table.
    ///
    /// - Parameters:
    ///   - database: The database the join table is on.
    ///   - type: The type of join this is.
    ///   - table: The name of the table to join to.
    init(database: Database, type: JoinType, table: String) {
        self.type = type
        self.table = table
        super.init(database: database)
    }
    
    func on(first: String, op: Operator, second: String, boolean: WhereBoolean = .and) -> JoinClause {
        self.whereColumn(first: first, op: op, second: second, boolean: boolean)
        return self
    }

    func orOn(first: String, op: Operator, second: String) -> JoinClause {
        return self.on(first: first, op: op, second: second, boolean: .or)
    }
}
