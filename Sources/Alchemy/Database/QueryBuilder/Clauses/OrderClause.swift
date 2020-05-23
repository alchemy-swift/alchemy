import Foundation

public struct OrderClause {

    public enum Sort: String {
        case asc
        case desc
    }

    let column: Column
    let direction: Sort
}

extension OrderClause: Sequelizable {
    func toSQL() -> SQL {
        if let raw = column as? Raw {
            return raw
        }
        return SQL("\(column) \(direction)")
    }
}
