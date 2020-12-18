import NIO

/// A protocol representing a relationship between two `Model`s. Contains only those two types and
/// functionality for eager loading this relationship.
public protocol Relationship {
    associatedtype From: Model
    associatedtype To: RelationAllowed
    
    func load(
        _ from: [From],
        with nestedQuery: @escaping (ModelQuery<To.Value>) -> ModelQuery<To.Value>,
        from eagerLoadKeyPath: KeyPath<From, Self>
    ) -> EventLoopFuture<[From]>
}

/// This protocol exists
public protocol RelationAllowed {
    associatedtype Value: Model
    var elementType: Value.Type { get }

    static func from(_ value: Value?) throws -> Self
}

extension Model where Value == Self {
    public var elementType: Self.Type { Self.self }
    public static func from(_ value: Value?) throws -> Self {
        try value.unwrap(or: RuneError.relationshipWasNil)
    }
}

extension Optional: RelationAllowed where Wrapped: Model {
    public var elementType: Wrapped.Type { Wrapped.self }
    public static func from(_ value: Wrapped?) throws -> Optional<Wrapped> { value }
}
