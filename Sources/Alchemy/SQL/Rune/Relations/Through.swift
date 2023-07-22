/// Used to infer keys for relationships.
public enum SQLKey: CustomStringConvertible {
    case specified(String)
    case inferred(String)

    var string: String {
        switch self {
        case .specified(let string): return string
        case .inferred(let string): return string
        }
    }

    public var description: String {
        string
    }

    func infer(_ key: String) -> SQLKey {
        switch self {
        case .specified: return self
        case .inferred: return .inferred(key)
        }
    }

    func specify(_ key: String?) -> SQLKey {
        key.map { .specified($0) } ?? self
    }

    static func infer(_ key: String) -> SQLKey {
        .inferred(key)
    }
}

let kLookupAlias = "__lookup"

struct Through {
    let table: String
    let from: SQLKey
    let to: SQLKey
}
