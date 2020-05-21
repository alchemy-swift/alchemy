/// So that `Model`, `Model?` & `[Model]` can have similar functionality.
public protocol RelationAllowed {
    associatedtype Value: Model
    var elementType: Value.Type { get }
}

extension RelationAllowed {
    public var elementType: Self.Type { Self.self }
}

extension Optional: RelationAllowed where Wrapped: Model {
    public var elementType: Wrapped.Type { Wrapped.self }
}
