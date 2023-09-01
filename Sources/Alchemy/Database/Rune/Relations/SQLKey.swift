/// Used to infer keys for relationships.
public enum SQLKey: CustomStringConvertible {
    case specified(String)
    case inferred(String)

    public var string: String {
        switch self {
        case .specified(let string): 
            return string
        case .inferred(let string): 
            return string
        }
    }

    public var description: String {
        string
    }

    public func infer(_ key: String) -> SQLKey {
        switch self {
        case .specified: 
            return self
        case .inferred: 
            return .inferred(key)
        }
    }

    public func specify(_ key: String?) -> SQLKey {
        key.map { .specified($0) } ?? self
    }

    public static func infer(_ key: String) -> SQLKey {
        .inferred(key)
    }
}

extension Database {
    func inferReferenceKey(_ table: (some Model).Type) -> SQLKey {
        inferReferenceKey(table.table)
    }

    func inferReferenceKey(_ table: String) -> SQLKey {
        .infer(keyMapping.encode(table.singularized + "Id"))
    }

    func inferPrimaryKey() -> SQLKey {
        .infer(keyMapping.encode("Id"))
    }
}
