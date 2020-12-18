/// So that `Model` & `Model?` can have similar functionality.
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
