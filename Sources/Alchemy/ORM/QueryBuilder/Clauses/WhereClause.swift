import Foundation

protocol WhereClause: Sequelizable {
    var operators: [String] { get }
}

extension WhereClause {
    var operators: [String] {
        [
        "=", "<", ">", "<=", ">=", "<>", "!=", "<=>",
        "like", "like binary", "not like", "ilike",
        "&", "|", "^", "<<", ">>",
        "rlike", "not rlike", "regexp", "not regexp",
        "~", "~*", "!~", "!~*", "similar to",
        "not similar to", "not ilike", "~~*", "!~~*",
        ]
    }
}

public enum WhereBoolean: String {
    case and
    case or
}

public struct WhereValue {
    let key: String
    let op: String
    let value: Parameter
    var boolean: WhereBoolean = .and
}

extension WhereValue: WhereClause {
    func toSQL() -> SQL {
        return SQL("\(boolean) \(key) \(op) ?", binding: value)
    }
}


public struct WhereColumn {
    let first: String
    let op: String
    let second: Expression
    var boolean: WhereBoolean = .and
}

extension WhereColumn: WhereClause {
    func toSQL() -> SQL {
        return SQL("\(boolean) \(first) \(op) \(second.description)")
    }
}


public struct WhereIn {

    public enum InType: String {
        case `in`
        case notIn
    }

    let key: String
    let values: [Parameter]
    let type: InType
    var boolean: WhereBoolean = .and
}

extension WhereIn: WhereClause {
    func toSQL() -> SQL {
        let placeholders = Array(repeating: "?", count: values.count)
        return SQL("\(boolean) \(key) \(type)(\(placeholders))", bindings: values)
    }
}


public struct WhereRaw {
    let query: String
    let values: [Parameter]
    var boolean: WhereBoolean = .and
}

extension WhereRaw: WhereClause {
    func toSQL() -> SQL {
        return SQL("\(boolean) \(self.query)", bindings: values)
    }
}


struct WhereSubquery {}

