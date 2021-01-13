import Foundation

/// A clause for ordering rows by a certain column.
public struct OrderClause {
    /// A sorting direction.
    public enum Sort: String {
        /// Sort elements in ascending order.
        case asc
        /// Sort elements in descending order.
        case desc
    }
    
    /// The column to order by.
    let column: Column
    /// The direction to order by.
    let direction: Sort
}

extension OrderClause: Sequelizable {
    public func toSQL() -> SQL {
        if let raw = column as? Raw {
            return raw
        }
        return SQL("\(column) \(direction)")
    }
}
