import Foundation

public struct OrderClause {

    public enum Sort: String {
        case asc
        case desc
    }

    let column: String
    let direction: Sort
}

extension OrderClause: Sequelizable {
    func toSQL() -> SQL {
        return SQL("\(column) \(direction)")
    }
}
