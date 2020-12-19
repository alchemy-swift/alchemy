import NIO

/// A protocol representing a relationship between two `Model`s. Contains only those two types and
/// functionality for eager loading this relationship.
public protocol Relationship {
    /// The `From` model from the perspective of this relationship. Likely the type that the
    /// `Relationship` is a property on.
    associatedtype From: Model
    
    /// The `To` model from the perspective of this relationship. Likely the type that the
    /// `Relationship` is _not_ a property on.
    associatedtype To: ModelMaybeOptional
    
    /// Given an array of `From`s, this function loads objects from the relationship
    /// `eagerLoadKeyPath` and sets them on each `From`.
    ///
    /// - Parameters:
    ///   - from: the array of `From`s to eager load a relationship on.
    ///   - nestedQuery: a closure for generating the query to find the related `To` objects.
    ///   - eagerLoadKeyPath: the `KeyPath` of the relationship. Once loaded, the `To` objects will
    ///                       be set here.
    /// - Returns: a future containing the `From` models, with the relationships at the
    ///            `eagerLoadKeyPath` populated & ready for access.
    func loadRelationships(
        for from: [From],
        query nestedQuery: @escaping (ModelQuery<To.Value>) -> ModelQuery<To.Value>,
        into eagerLoadKeyPath: KeyPath<From, Self>
    ) -> EventLoopFuture<[From]>
}

/// Either a `Model` or a `Model?`.
///
/// This protocol exists so that `Model?` and `Model` can be treated similarly in relationship
/// property wrappers. Sometimes a relationship may be optional, sometimes it may be required.
/// Alchemy supports both cases.
public protocol ModelMaybeOptional {
    /// The underlying `Model` type. `Self` if this is a `Model`, `Wrapped` if this is a `Model?`.
    associatedtype Value: Model
    
    /// Given an optional object of type `Value`, convert that to this type. Used for managing the
    /// type system when putting eagerly loaded data into relationship properties.
    ///
    /// - Parameter value: the value to convert.
    /// - Throws: an error if the optional value was unable to be converted to `Self`.
    /// - Returns: the `value` converted to type `Self`.
    static func from(_ value: Value?) throws -> Self
}

extension Model {
    // MARK: ModelMaybeOptional
    
    public static func from(_ value: Self?) throws -> Self {
        try value.unwrap(or: RuneError.relationshipWasNil)
    }
}

extension Optional: ModelMaybeOptional where Wrapped: Model {
    // MARK: ModelMaybeOptional
    
    public static func from(_ value: Wrapped?) throws -> Self {
        value
    }
}
