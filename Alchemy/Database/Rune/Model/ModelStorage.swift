public final class ModelStorage<M: Model>: Codable {
    public var id: M.PrimaryKey?
    public var row: SQLRow? {
        didSet {
            if let value = try? row?.require(M.primaryKey) {
                self.id = try? M.PrimaryKey(value: value)
            }
        }
    }

    public var relationships: [String: Any]
    public var encodableCache: [String: AnyEncodable]

    public init() {
        self.id = nil
        self.row = nil
        self.relationships = [:]
        self.encodableCache = [:]
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
        storage.encodableCache = otherModel.storage.encodableCache
    }

    func cache<To>(_ value: To, at key: String) {
        if let value = value as? Encodable {
            storage.encodableCache[key] = AnyEncodable(value)
        } else {
            storage.relationships[key] = value
        }
    }

    func cached<To>(at key: String, _ type: To.Type = To.self) throws -> To? {
        guard let value = storage.relationships[key] ?? storage.encodableCache[key] else {
            return nil
        }

        guard let value = value as? To else {
            throw RuneError("Eager load cache type mismatch!")
        }

        return value
    }

    func cacheExists(_ key: String) -> Bool {
        storage.relationships[key] != nil || storage.encodableCache[key] != nil
    }
}
