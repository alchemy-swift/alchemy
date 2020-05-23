import Foundation

public enum JoinType: String {
    case inner
    case outer
    case left
    case right
    case cross
}

class JoinClause: Query {

    public let type: JoinType
    public let table: String

    init(query: Query, type: JoinType, table: String) {
        self.type = type
        self.table = table
        super.init(database: query.database)
    }

    func on(first: String, op: Operator, second: String, boolean: WhereBoolean = .and) -> JoinClause {
        self.whereColumn(first: first, op: op, second: second, boolean: boolean)
        return self
    }

    func orOn(first: String, op: Operator, second: String) -> JoinClause {
        return self.on(first: first, op: op, second: second, boolean: .or)
    }
}
