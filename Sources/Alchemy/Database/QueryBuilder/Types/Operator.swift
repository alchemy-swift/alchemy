import Foundation

public enum Operator: CustomStringConvertible {
    case equals
    case lessThan
    case greaterThan
    case lessThanOrEqualTo
    case greaterThanOrEqualTo
    case notEqualTo
    case like
    case notLike
    case raw(operator: String)

    public var description: String {
        switch self {
        case .equals: return "="
        case .lessThan: return "<"
        case .greaterThan: return ">"
        case .lessThanOrEqualTo: return "<="
        case .greaterThanOrEqualTo: return ">="
        case .notEqualTo: return "!="
        case .like: return "LIKE"
        case .notLike: return "NOT LIKE"
        case .raw(let value): return value
        }
    }
}
