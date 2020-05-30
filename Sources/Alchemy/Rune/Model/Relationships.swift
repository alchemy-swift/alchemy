import Foundation
import NIO

/// Relationships.
extension Model {
    public typealias HasOne<To: RelationAllowed> = _HasOne<Self, To>
    public typealias HasMany<To: RelationAllowed> = _HasMany<Self, To>
    public typealias BelongsTo<To: RelationAllowed> = _BelongsTo<Self, To>
}

protocol Relationship: class {
    associatedtype From: Model

    /// Given a list of `From`s, load the relationships in order.
    static func load(_ from: [From]) -> EventLoopFuture<[Self]>
}

@propertyWrapper
public final class _HasOne<From: Model, To: RelationAllowed>: Relationship, Codable {
    private var value: To?
    private var toKey: String?

    public var wrappedValue: To {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }

    required init(value: To) {
        self.value = value
        self.toKey = ""
    }

    static func load(_ from: [From]) -> EventLoopFuture<[_HasOne]> {
        To.Value.query()
            .where("id" == "")
            .getAll()
            .mapEach { .init(value: To.from($0)) }
    }

    public init(to: KeyPath<To, From>) {
        self.toKey = to.keyPathObject.kvcString ?? "wat"
    }

    public required init(from decoder: Decoder) throws {}
    
    public var projectedValue: _HasOne<From, To> {
        self
    }
    
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class _HasMany<From: Model, To: RelationAllowed>: Relationship, Codable {
    private var value: [To]?

    public var wrappedValue: [To] {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
    }

    public var projectedValue: _HasMany<From, To> { self }

    /// One to Many
    public init(to: KeyPath<To, From>) {

    }

    /// Many to Many
    public init<Through: Model>(from: KeyPath<Through, From>, to: KeyPath<Through, To>) {

    }

    static func load(_ from: [From]) -> EventLoopFuture<[_HasMany]> {
        fatalError()
    }
    
    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {}
}

protocol AnyBelongsTo {}

@propertyWrapper
/// The child of a one to many or a one to one.
public final class _BelongsTo<Child: Model, Parent: RelationAllowed>: Relationship, Codable, AnyBelongsTo {
    public var id: Parent.Value.Identifier

    private var value: Parent?
    
    public var wrappedValue: Parent {
        get {
            guard let value = self.value else { fatalError("Please load first") }
            return value
        }
        set { self.value = newValue }
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

    static func load(_ from: [Child]) -> EventLoopFuture<[_BelongsTo]> {
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
