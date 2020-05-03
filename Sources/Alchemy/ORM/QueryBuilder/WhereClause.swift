import Foundation

public struct WhereClause {
    let first: String
    let op: String
    let second: Clause
    let boolean: String

    let operators = [
        "=", "<", ">", "<=", ">=", "<>", "!=", "<=>",
        "like", "like binary", "not like", "ilike",
        "&", "|", "^", "<<", ">>",
        "rlike", "not rlike", "regexp", "not regexp",
        "~", "~*", "!~", "!~*", "similar to",
        "not similar to", "not ilike", "~~*", "!~~*",
    ]

    init(first: String, op: String, second: String, boolean: String = "and") {
        self.first = first
        self.op = op
        self.second = Expression(value: second)
        self.boolean = boolean
    }

    init(key: String, op: String, value: Clause, boolean: String = "and") {
        self.first = key
        self.op = op
        self.second = value
        self.boolean = boolean
    }

    func toString() -> String {
        // TODO: Make sure column names are wrapped
        let parameter = second is Expression ? second.toString() : "?"
        return "\(boolean) \(first) \(op) \(parameter)"
    }
}
