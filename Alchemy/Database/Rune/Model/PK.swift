public final class ModelStorage: Codable {
    var row: SQLRow?
    var relationships: [String: Any]

    public init() {
        self.relationships = [:]
        self.row = nil
    }

    public func encode(to encoder: Encoder) throws {
        // instead, use the KeyedEncodingContainer extension below.
        preconditionFailure("Directly encoding ModelStorage not supported!")
    }

    public init(from decoder: Decoder) throws {
        // instead, use the KeyedDecodingContainer extension below.
        preconditionFailure("Directly decoding ModelStorage not supported!")
    }
}

extension KeyedDecodingContainer {
    public func decode(
        _ type: ModelStorage,
        forKey key: Self.Key
    ) throws -> ModelStorage {
        // decode id
        ModelStorage()
    }
}

extension KeyedEncodingContainer {
    public mutating func encode(
        _ value: ModelStorage,
        forKey key: KeyedEncodingContainer<K>.Key
    ) throws {
        // encode id
        // encode relationships
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
