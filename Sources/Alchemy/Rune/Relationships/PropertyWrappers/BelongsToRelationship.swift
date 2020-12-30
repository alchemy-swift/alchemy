import NIO

/// A type erased `BelongsToRelationship`. Used for special casing decoding behavior for
/// `BelongsTo`s.
protocol AnyBelongsTo {}

@propertyWrapper
/// The child of a 1 - M or a 1 - 1 relationship. Backed by an identifier of the parent, when
/// encoded to a database, this type attempt to write that identifier to a column named 
/// `<property-name>_id`.
///
/// Example:
/// ```
/// struct Pet: Model {
///     static let table = "pets"
///     ...
///
///     @BelongsTo
///     var owner: User // The ID value of this User will be stored under the `owner_id` column in
///                     // the `pets` table.
/// }
/// ```
public final class BelongsToRelationship<
    Child: Model,
    Parent: ModelMaybeOptional
>: AnyBelongsTo, Codable, Relationship {
    public typealias From = Child
    public typealias To = Parent
    
    /// The identifier of this relationship's parent.
    public var id: Parent.Value.Identifier! {
        didSet {
            self.value = nil
        }
    }
    
    /// The underlying relationship object, if there is one. Populated by eager loading.
    private var value: Parent?
    
    /// The related `Model` object. Accessing this will `fatalError` if the relationship is not
    /// already loaded via eager loading or set manually.
    public var wrappedValue: Parent {
        get {
            guard let value = self.value else { fatalError("Relationship of type `\(name(of: Parent.self))` was not loaded!") }
            return value
        }
        set { self.value = newValue }
    }
    
    /// The projected value of this property wrapper is itself. Used for when a reference to the
    /// _relationship_ type is needed, such as during eager loads.
    public var projectedValue: Child.BelongsTo<Parent> {
        self
    }
    
    /// Initialize this relationship with an `Identifier` of the `Parent` type.
    ///
    /// - Parameter parentID: the identifier of the `Parent` to which this child belongs.
    public init(_ parentID: Parent.Value.Identifier) {
        self.id = parentID
    }
    
    /// Initialize this relationship with an instance of `Parent`.
    ///
    /// - Parameter parent: the `Parent` object to which this child belongs.
    public init(_ parent: Parent.Value) {
        guard let id = parent.id else {
            fatalError("Can't form a relation with an unidentified object.")
        }

        self.id = id
        // `.from` only throws if it's passed nil so this will always succeed.
        self.value = try? Parent.from(parent)
    }
    
    /// Initializes this `BelongsToRelationship` with nil values. Should only be called on a
    /// `BelongsTo` that has an `Optional` `Parent` type.
    ///
    /// - Parameter nil: a void closure. Ideally this signature would be `init()` but that seems to
    ///                  throw a compiler error related to property wrappers.
    private init(nil: Void) {
        self.id = nil
        self.value = nil
    }
    
    // MARK: Relationship
    
    public func loadRelationships(
        for from: [Child],
        query nestedQuery: @escaping (ModelQuery<Parent.Value>) -> ModelQuery<Parent.Value>,
        into eagerLoadKeyPath: KeyPath<Child, Child.BelongsTo<Parent>>) -> EventLoopFuture<[Child]>
    {
        let parentIDs = from.compactMap { $0[keyPath: eagerLoadKeyPath].id }.uniques
        let initialQuery = Parent.Value.query().where(key: "id", in: parentIDs)
        return nestedQuery(initialQuery)
            .getAll()
            .flatMapThrowing { parents in
                var updatedResults = [Child]()
                let dict = Dictionary(grouping: parents, by: { $0.id! })
                for child in from {
                    let parentID = child[keyPath: eagerLoadKeyPath].id!
                    let parent = dict[parentID]
                    child[keyPath: eagerLoadKeyPath].wrappedValue = try Parent.from(parent?.first)
                    updatedResults.append(child)
                }

                return updatedResults
            }
    }

    // MARK: Codable
    
    public func encode(to encoder: Encoder) throws {
        if !(encoder is ModelEncoder) {
            try self.value.encode(to: encoder)
        } else {
            // When encoding to the database, just encode the Parent's ID.
            var container = encoder.singleValueContainer()
            try container.encode(self.id)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.id = nil
        } else {
            // When decode from a database, just decode the Parent's ID.
            self.id = try container.decode(Parent.Value.Identifier.self)
        }
    }
}

extension BelongsToRelationship: ExpressibleByNilLiteral where Parent: AnyOptional {
    // MARK: ExpressibleByNilLiteral
    
    public convenience init(nilLiteral: ()) {
        self.init(nil: nilLiteral)
    }
}
