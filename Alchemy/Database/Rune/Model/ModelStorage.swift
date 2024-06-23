public final class ModelStorage<M: Model>: Codable, Equatable {
    public var id: M.ID?
    public var row: SQLRow? {
        didSet {
            if let id = row?[M.idKey] {
                self.id = try? M.ID(value: id)
            }
        }
    }

    public var relationships: [CacheKey: Any]

    public init(id: M.ID? = nil) {
        self.id = id
        self.row = nil
        self.relationships = [:]
    }

    // MARK: SQL

    public func write(to writer: inout SQLRowWriter) throws {
        if let id {
            try writer.put(id, at: M.idKey)
        }
    }

    public func read(from reader: SQLRowReader) throws {
        id = try reader.require(M.ID.self, at: M.idKey)
        row = reader.row
    }

    // MARK: Codable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: GenericCodingKey.self)
        
        // 0. encode id
        if let id {
            try container.encode(id, forKey: .key(M.idKey))
        }

        // 1. encode encodable relationships
        for (key, relationship) in relationships {
            if let relationship = relationship as? Encodable, let name = key.name {
                try container.encode(AnyEncodable(relationship), forKey: .key(name))
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: GenericCodingKey.self)
        let key: GenericCodingKey = .key(M.idKey)
        if container.contains(key) {
            self.id = try container.decode(M.ID.self, forKey: key)
        }

        self.row = nil
        self.relationships = [:]
    }

    // MARK: Equatable

    public static func == (lhs: ModelStorage<M>, rhs: ModelStorage<M>) -> Bool {
        lhs.id == rhs.id
    }
}

extension Model {
    public typealias Storage = ModelStorage<Self>
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
