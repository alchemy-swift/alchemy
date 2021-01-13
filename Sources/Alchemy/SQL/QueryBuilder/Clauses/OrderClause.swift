import Foundation

/// A clause for ordering rows by a certain column.
public struct OrderClause: Sequelizable {
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
    
    // MARK: - Sequelizable
    
    public func toSQL() -> SQL {
        if let raw = column as? SQL {
            return raw
        }
        return SQL("\(column) \(direction)")
    }
}
