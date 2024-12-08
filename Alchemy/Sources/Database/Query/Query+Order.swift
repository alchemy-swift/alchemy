/// A clause for ordering rows by a certain column.
public struct SQLOrder: Equatable {
    /// A sorting direction.
    public enum Direction: String {
        /// Sort elements in ascending order.
        case asc = "ASC"
        /// Sort elements in descending order.
        case desc = "DESC"
    }

    /// The column to order by.
    let column: String
    /// The direction to order by.
    let direction: Direction
}

extension Query {
    /// Order the data from the query based on a column and direction.
    public func orderBy(_ column: String, direction: SQLOrder.Direction = .asc) -> Self {
        orders.append(SQLOrder(column: column, direction: direction))
        return self
    }
}
