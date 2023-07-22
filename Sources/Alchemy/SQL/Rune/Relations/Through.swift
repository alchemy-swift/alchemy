enum SQLKey: CustomStringConvertible {
    case specified(String)
    case inferred(String)

    var string: String {
        switch self {
        case .specified(let string): return string
        case .inferred(let string): return string
        }
    }

    var description: String {
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

struct Through {
    let table: Table
    let from: String?
    let to: String?
}

enum Table {
    case model(any Model.Type)
    case string(String)

    func idKey(mapping: KeyMapping) -> String {
        switch self {
        case .model(let model):
            return model.idKey
        case .string:
            return mapping.encode("Id")
        }
    }

    func referenceKey(mapping: KeyMapping) -> String {
        switch self {
        case .model(let model):
            return model.referenceKey
        case .string(let string):
            return mapping.encode(string.singularized + "Id")
        }
    }

    var string: String {
        switch self {
        case .model(let model):
            return model.table
        case .string(let string):
            return string
        }
    }
}
