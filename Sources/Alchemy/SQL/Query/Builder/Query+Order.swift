/// A clause for ordering rows by a certain column.
public struct SQLOrder: Equatable {
    /// A sorting direction.
    public enum Direction: String {
        /// Sort elements in ascending order.
        case asc
        /// Sort elements in descending order.
        case desc
    }

    /// The column to order by.
    let column: String
    /// The direction to order by.
    let direction: Direction
}

extension Query {
    /// Order the data from the query based on given clause.
    ///
    /// - Parameter order: The `OrderClause` that defines the
    ///   ordering.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orderBy(_ order: SQLOrder) -> Self {
        query.orders.append(order)
        return self
    }

    /// Order the data from the query based on a column and direction.
    ///
    /// - Parameters:
    ///   - column: The column to order data by.
    ///   - direction: The `OrderClause.Sort` direction (either `.asc`
    ///     or `.desc`). Defaults to `.asc`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orderBy(_ column: String, direction: SQLOrder.Direction = .asc) -> Self {
        orderBy(SQLOrder(column: column, direction: direction))
    }
}
