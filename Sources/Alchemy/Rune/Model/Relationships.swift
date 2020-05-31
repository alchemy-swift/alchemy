import Foundation
import NIO

/// Relationships need to...
/// 1. encode an id value (`BelongsTo`) or nothing (`HasOne`, `HasMany`)
/// 2. decode properly, with `KeyPath` & `String` info in tact.

/// Relationships.
extension Model {
    public typealias HasOne<To: RelationAllowed> = _HasOne<Self, To>
    public typealias HasMany<To: RelationAllowed> = _HasMany<Self, To>
    public typealias BelongsTo<To: RelationAllowed> = _BelongsTo<Self, To>
}

public protocol Relationship {
    associatedtype From: Model
    associatedtype To: RelationAllowed
    func load(_ from: [From], from eagerLoadKeyPath: KeyPath<From, Self>) -> EventLoopFuture<[From]>
}

public protocol AnyHas {}

class RelationshipData {
    private static var dict: [String: (String, AnyKeyPath)] = [:]
    
    static func store<From: Model, To: Model>(
        from: From.Type,
        to: To.Type,
        fromStored: String,
        keyString: String,
        keyPath: AnyKeyPath
    ) {
        let key = "\(From.tableName)_\(To.tableName)_\(fromStored)"
        dict[key] = (keyString, keyPath)
    }
    
    static func get<From: Model, To: Model>(
        from: From.Type,
        to: To.Type,
        fromStored: String
    ) -> (String, AnyKeyPath)? {
        let key = "\(From.tableName)_\(To.tableName)_\(fromStored)"
        return dict[key]
    }
}

@propertyWrapper
public final class _HasOne<From: Model, To: RelationAllowed>: Codable, AnyHas, Relationship {
    private var value: To?

    private var toKey: String
    private var toKeyPath: KeyPath<To.Value, To.Value.BelongsTo<From>>!

    public var wrappedValue: To {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }
    
    public var projectedValue: _HasOne<From, To> { self }

    public init(value: To) {
        self.value = value
        self.toKey = ""
    }

    public init(this: String, to key: String, via: KeyPath<To.Value, To.Value.BelongsTo<From>>) {
        RelationshipData.store(from: From.self, to: To.Value.self, fromStored: this, keyString: key, keyPath: via)
        self.toKey = key
        self.toKeyPath = via
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingKey = try container.decode(String.self)
        
        guard let key = RelationshipData.get(from: From.self, to: To.Value.self, fromStored: codingKey) else {
            fatalError("Unable to find the foreign key of this relationship ;_;")
        }
        
        self.toKey = key.0
        self.toKeyPath = key.1 as? KeyPath<To.Value, To.Value.BelongsTo<From>>
    }
    
    public func load(
        _ from: [From],
        from eagerLoadKeyPath: KeyPath<From, From.HasOne<To>>) -> EventLoopFuture<[From]>
    {
        To.Value.query()
            // Should only pull on per id
            .where(key: self.toKey, in: from.compactMap { $0.id })
            .getAll()
            .flatMapThrowing { relationshipResults in
                var updatedResults = [From]()
                let dict = Dictionary(grouping: relationshipResults, by: { $0[keyPath: self.toKeyPath].id! })
                for result in from {
                    let values = dict[result.id as! From.Value.Identifier]
                    result[keyPath: eagerLoadKeyPath].wrappedValue = try To.from(values?.first)
                    updatedResults.append(result)
                }

                return updatedResults
            }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = self.value as? To.Value {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}

@propertyWrapper
public final class _HasMany<From: Model, To: RelationAllowed>: Codable, AnyHas, Relationship {
    private var value: [To]?

    private var toKey: String
    private var toKeyPath: KeyPath<To.Value, To.Value.BelongsTo<From>>!

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }

    public var projectedValue: _HasMany<From, To> { self }

    /// One to Many
    public init(this: String, to key: String, via: KeyPath<To.Value, To.Value.BelongsTo<From>>) {
        RelationshipData.store(from: From.self, to: To.Value.self, fromStored: this, keyString: key, keyPath: via)
        self.toKey = key
        self.toKeyPath = via
    }

    private init(value: [To]) {
        // Can init with RelationshipData?
        self.value = value
        self.toKey = ""
    }

    /// Many to Many
    public init<Through: Model>(through: Through.Type, from fromKey: String, to toKey: String) {
        fatalError("TODO")
    }

    public func load(_ from: [From], from eagerLoadKeyPath: KeyPath<From, _HasMany<From, To>>) -> EventLoopFuture<[From]> {
        To.Value.query()
            // Should only pull on per id
            .where(key: self.toKey, in: from.compactMap { $0.id })
            .getAll()
            .flatMapThrowing { relationshipResults in
                var updatedResults = [From]()
                let dict = Dictionary(grouping: relationshipResults, by: { $0[keyPath: self.toKeyPath].id! })
                for result in from {
                    let values = dict[result.id as! From.Value.Identifier]
                    result[keyPath: eagerLoadKeyPath].wrappedValue = try values?.map { try To.from($0) } ?? []
                    updatedResults.append(result)
                }

                return updatedResults
            }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = self.value as? [To.Value] {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingKey = try container.decode(String.self)
        
        guard let key = RelationshipData.get(from: From.self, to: To.Value.self, fromStored: codingKey) else {
            fatalError("Unable to find the foreign key of this relationship ;_;")
        }
        
        self.toKey = key.0
        self.toKeyPath = key.1 as? KeyPath<To.Value, To.Value.BelongsTo<From>>
    }
}

public protocol AnyBelongsTo {}

@propertyWrapper
/// The child of a one to many or a one to one.
public final class _BelongsTo<Child: Model, Parent: RelationAllowed>: AnyBelongsTo, Codable {
    public var id: Parent.Value.Identifier!

    private var value: Parent?
    
    public var wrappedValue: Parent {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }

    public init() {
        
    }
    
    public init(_ parent: Parent.Value) {
        guard let id = parent.id else {
            fatalError("Can't form a relation with an unidentified object.")
        }

        self.id = id
    }

    public var projectedValue: _BelongsTo<Child, Parent> {
        self
    }

    func load(_ from: [Child]) -> EventLoopFuture<[_BelongsTo]> {
        fatalError()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
    
    public init(from decoder: Decoder) throws {
        self.id = try decoder.singleValueContainer().decode(Parent.Value.Identifier.self)
    }
}
