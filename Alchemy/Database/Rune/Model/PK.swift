public final class ModelStorage {
    var row: SQLRow?
    var relationships: [String: Any]

    public init() {
        self.relationships = [:]
        self.row = nil
    }

    static var new: ModelStorage {
        ModelStorage()
    }
}

extension Model {
    public internal(set) var row: SQLRow? {
        get { storage.row }
        nonmutating set { storage.row = newValue }
    }

    func mergeCache(_ otherModel: Self) {
        storage.relationships = otherModel.storage.relationships
    }

    func cache<To>(_ value: To, at key: String) {
        storage.relationships[key] = value
    }

    func cached<To>(at key: String, _ type: To.Type = To.self) throws -> To? {
        guard let value = storage.relationships[key] else {
            return nil
        }

        guard let value = value as? To else {
            throw RuneError("Eager load cache type mismatch!")
        }

        return value
    }

    func cacheExists(_ key: String) -> Bool {
        storage.relationships[key] != nil
    }
}
