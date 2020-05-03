import Foundation

class JoinClause: Query {

    public let type: String
    public let table: String

    init(query: Query, type: String, table: String) {
        self.type = type
        self.table = table
        super.init(database: query.database)
    }


    func on(first: String, op: String, second: String, boolean: WhereBoolean = .and) -> JoinClause {
        self.whereColumn(first: first, op: op, second: second, boolean: boolean)
        return self
    }

    func orOn(first: String, op: String, second: String) -> JoinClause {
        return self.on(first: first, op: op, second: second, boolean: .or)
    }

}
