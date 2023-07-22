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
