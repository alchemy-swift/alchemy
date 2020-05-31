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

public protocol AnyHas {}

class RelationshipData {
    private static var dict: [String: String] = [:]
    
    static func store<From: Model, To: Model>(from: From.Type, to: To.Type, fromStored: String, toKey: String) {
        let key = "\(From.tableName)_\(To.tableName)_\(fromStored)"
        dict[key] = toKey
    }
    
    static func get<From: Model, To: Model>(from: From.Type, to: To.Type, fromStored: String) -> String? {
        let key = "\(From.tableName)_\(To.tableName)_\(fromStored)"
        return dict[key]
    }
}

@propertyWrapper
public final class _HasOne<From: Model, To: RelationAllowed>: Codable, AnyHas {
    private var value: To?

    private var toKey: String

    public var wrappedValue: To {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }

    init(value: To) {
        self.value = value
        self.toKey = ""
    }

    func load(_ from: [From]) -> EventLoopFuture<[To.Value]> {
        To.Value.query()
            // Should only pull on per id
            .where(key: self.toKey, in: from.compactMap { $0.id })
            .getAll()
    }

    public init(this: String, to key: String) {
        RelationshipData.store(from: From.self, to: To.Value.self, fromStored: this, toKey: key)
        self.toKey = key
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingKey = try container.decode(String.self)
        
        guard let key = RelationshipData.get(from: From.self, to: To.Value.self, fromStored: codingKey) else {
            fatalError("Unable to find the foreign key of this relationship ;_;")
        }
        
        self.toKey = key
    }
    
    public var projectedValue: _HasOne<From, To> { self }
    
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
public final class _HasMany<From: Model, To: RelationAllowed>: Codable, AnyHas {
    private var value: [To]?

    private var toKey: String
    private var fromKey: String?
    private var throughTable: String?

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }

    public var projectedValue: _HasMany<From, To> { self }

    /// One to Many
    public init(to key: String) {
        self.toKey = key
    }

    private init(value: [To]) {
        fatalError()
    }

    /// Many to Many
    public init<Through: Model>(through: Through.Type, from fromKey: String, to toKey: String) {
        fatalError()
    }

    func load(_ from: [From]) -> EventLoopFuture<[_HasMany]> {
        To.Value.query()
            // Should only pull on per id
            .where(key: self.toKey, in: from.compactMap { $0.id })
            .getAll()
            .map { results in
                var orderedDict = OrderedDictionary<From.Identifier, [To]>()
                for fromID in from.compactMap({ $0.id }) {
                    orderedDict[fromID] = []
                }
                for result in results {
//                    orderedDict[result[keyPath: ]]
                }

                fatalError()
//                return Array(orderedDict.orderedValues)
//                .init(value: $0.map { To.from($0) })
            }
    }
    
    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {fatalError()}
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
