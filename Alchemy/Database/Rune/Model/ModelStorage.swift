public final class ModelStorage<M: Model>: Codable {
    public var id: M.PrimaryKey?
    public var row: SQLRow?
    var relationships: [String: Any]

    public init() {
        self.id = nil
        self.row = nil
        self.relationships = [:]
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

extension Model {
    public typealias Storage = ModelStorage<Self>
}

extension KeyedDecodingContainer {
    public func decode<M: Model>(
        _ type: ModelStorage<M>,
        forKey key: Self.Key
    ) throws -> ModelStorage<M> {
        let storage = M.Storage()
        let hasId = allKeys.contains { $0.stringValue == M.primaryKey }
        if hasId, let key = K(stringValue: M.primaryKey) {
            storage.id = try decode(M.PrimaryKey.self, forKey: key)
        }

        return storage
    }
}

extension KeyedEncodingContainer {
    public mutating func encode<M: Model>(
        _ value: ModelStorage<M>,
        forKey key: KeyedEncodingContainer<K>.Key
    ) throws {
        // encode id
        if let key = K(stringValue: M.primaryKey) {
            try encode(value.id, forKey: key)
        }

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
