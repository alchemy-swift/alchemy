import Foundation

public enum Operator: CustomStringConvertible, Equatable {
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

extension String {
    // MARK: Operators
    
    public static func == (lhs: String, rhs: SQLValueConvertible) -> WhereValue {
        return WhereValue(key: lhs, op: .equals, value: rhs.value)
    }

    public static func != (lhs: String, rhs: SQLValueConvertible) -> WhereValue {
        return WhereValue(key: lhs, op: .notEqualTo, value: rhs.value)
    }

    public static func < (lhs: String, rhs: SQLValueConvertible) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThan, value: rhs.value)
    }

    public static func > (lhs: String, rhs: SQLValueConvertible) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThan, value: rhs.value)
    }

    public static func <= (lhs: String, rhs: SQLValueConvertible) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThanOrEqualTo, value: rhs.value)
    }

    public static func >= (lhs: String, rhs: SQLValueConvertible) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThanOrEqualTo, value: rhs.value)
    }

    public static func ~= (lhs: String, rhs: SQLValueConvertible) -> WhereValue {
        return WhereValue(key: lhs, op: .like, value: rhs.value)
    }
}
