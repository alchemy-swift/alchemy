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

class RelationshipDataStorage {
    private static var dict: [String: RelationshipData] = [:]
    
    static func store<From: Model, To: Model>(
        from: From.Type,
        to: To.Type,
        fromStored: String,
        data: RelationshipData
    ) {
        let key = "\(From.tableName)_\(To.tableName)_\(fromStored)"
        dict[key] = data
    }
    
    static func get<From: Model, To: Model>(
        from: From.Type,
        to: To.Type,
        fromStored: String
    ) -> RelationshipData? {
        let key = "\(From.tableName)_\(To.tableName)_\(fromStored)"
        return dict[key]
    }
}

enum RelationshipData {
    /// The relationship is through two foreign keys on a pivot table.
    ///
    /// Pet -> PetVaccine -> Vaccine
    case pivot(
        fromKey: AnyKeyPath,
        fromKeyString: String,
        toKey: AnyKeyPath,
        toKeyString: String
    )
    /// The relationship is via a foreign key on the child.
    ///
    /// Pet -> User
    case foreignKey(
        key: AnyKeyPath,
        keyString: String
    )
}

@propertyWrapper
public final class _HasOne<From: Model, To: RelationAllowed>: Codable, AnyHas, Relationship {
    private var value: To?

    private var relationshipData: RelationshipData!

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
    }

    public init(this: String, to key: String, via: KeyPath<To.Value, To.Value.BelongsTo<From>>) {
        RelationshipDataStorage.store(
            from: From.self,
            to: To.Value.self,
            fromStored: this,
            data: .foreignKey(key: via, keyString: key)
        )
        self.relationshipData = .foreignKey(key: via, keyString: key)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingKey = try container.decode(String.self)
        
        guard let data = RelationshipDataStorage.get(from: From.self, to: To.Value.self, fromStored: codingKey) else {
            fatalError("Unable to find the data of this relationship ;_;")
        }
        
        self.relationshipData = data
    }
    
    public func load(
        _ from: [From],
        from eagerLoadKeyPath: KeyPath<From, From.HasOne<To>>) -> EventLoopFuture<[From]>
    {
        switch self.relationshipData {
        case let .foreignKey(key, keyString):
            let toKey = key as! KeyPath<To.Value, To.Value.BelongsTo<From>>
            return To.Value.query()
                // Should only pull on per id
                .where(key: keyString, in: from.compactMap { $0.id })
                .getAll()
                .flatMapThrowing { relationshipResults in
                    var updatedResults = [From]()
                    let dict = Dictionary(grouping: relationshipResults, by: { $0[keyPath: toKey].id! })
                    for result in from {
                        let values = dict[result.id as! From.Value.Identifier]
                        result[keyPath: eagerLoadKeyPath].wrappedValue = try To.from(values?.first)
                        updatedResults.append(result)
                    }

                    return updatedResults
                }
        default:
            fatalError("not ready yet")
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

    private var relationshipData: RelationshipData!

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
        RelationshipDataStorage.store(
            from: From.self,
            to: To.Value.self,
            fromStored: this,
            data: .foreignKey(key: via, keyString: key)
        )
        self.relationshipData = .foreignKey(key: via, keyString: key)
    }

    private init(value: [To]) {
        // Can init with RelationshipData?
        self.value = value
    }

    /// Many to Many
    public init<Through: Model>(
        named: String,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String
    ) {
        fatalError("TODO")
    }

    public func load(_ from: [From], from eagerLoadKeyPath: KeyPath<From, _HasMany<From, To>>) -> EventLoopFuture<[From]> {
        switch self.relationshipData {
        case let .foreignKey(key, keyString):
            let toKey = key as! KeyPath<To.Value, To.Value.BelongsTo<From>>
            return To.Value.query()
                // Should only pull on per id
                .where(key: keyString, in: from.compactMap { $0.id })
                .getAll()
                .flatMapThrowing { relationshipResults in
                    var updatedResults = [From]()
                    let dict = Dictionary(grouping: relationshipResults, by: { $0[keyPath: toKey].id! })
                    for result in from {
                        let values = dict[result.id as! From.Value.Identifier]
                        result[keyPath: eagerLoadKeyPath].wrappedValue = try values?.map { try To.from($0) } ?? []
                        updatedResults.append(result)
                    }

                    return updatedResults
                }
        default:
            fatalError("not ready yet")
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
        
        guard let data = RelationshipDataStorage.get(from: From.self, to: To.Value.self, fromStored: codingKey) else {
            fatalError("Unable to find the foreign key of this relationship ;_;")
        }
        
        self.relationshipData = data
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
