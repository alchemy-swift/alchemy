public final class ModelStorage<M: Model>: Codable {
    public var id: M.PrimaryKey?
    public var row: SQLRow? {
        didSet {
            if let value = try? row?.require(M.primaryKey) {
                self.id = try? M.PrimaryKey(value: value)
            }
        }
    }

    public var relationships: [CacheKey: Any]

    public init() {
        self.id = nil
        self.row = nil
        self.relationships = [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: GenericCodingKey.self)
        for (key, relationship) in relationships {
            if let relationship = relationship as? Encodable, let name = key.name {
                try container.encode(AnyEncodable(relationship), forKey: .key(name))
            }
        }
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
        M.Storage()
    }
}

extension KeyedEncodingContainer {
    public mutating func encode<M: Model>(
        _ value: ModelStorage<M>,
        forKey key: KeyedEncodingContainer<K>.Key
    ) throws {
        // ignore
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

    func cache<To>(_ value: To, at key: CacheKey) {
        storage.relationships[key] = value
    }

    func cached<To>(at key: CacheKey, _ type: To.Type = To.self) throws -> To? {
        guard let value = storage.relationships[key] else {
            return nil
        }

        guard let value = value as? To else {
            throw RuneError("Eager load cache type mismatch!")
        }

        return value
    }

    func cacheExists(_ key: CacheKey) -> Bool {
        storage.relationships[key] != nil
    }
}
