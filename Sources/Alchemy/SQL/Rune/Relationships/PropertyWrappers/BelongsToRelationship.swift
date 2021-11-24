import NIO

/// The child of a 1 - M or a 1 - 1 relationship. Backed by an
/// identifier of the parent, when encoded to a database, this
/// type attempt to write that identifier to a column named 
/// `<property-name>_id`.
///
/// Example:
/// ```swift
/// struct Pet: Model {
///     static let table = "pets"
///     ...
///
///     @BelongsTo
///     var owner: User // The ID value of this User will be stored
///                     // under the `owner_id` column in the
///                     // `pets` table.
/// }
/// ```
@propertyWrapper
public final class BelongsToRelationship<Child: Model, Parent: ModelMaybeOptional>: AnyBelongsTo, Relationship, Codable {
    public typealias From = Child
    public typealias To = Parent
    
    /// The identifier of this relationship's parent.
    public var id: Parent.Value.Identifier? {
        didSet {
            value = nil
        }
    }
    
    var idValue: SQLValue? { id.value }
    
    /// The underlying relationship object, if there is one. Populated
    /// by eager loading.
    private var value: Parent?
    
    /// The related `Model` object. Accessing this will `fatalError`
    /// if the relationship is not already loaded via eager loading
    /// or set manually.
    public var wrappedValue: Parent {
        get {
            do {
                return try Parent.from(value)
            } catch {
                fatalError("Relationship of type `\(name(of: Parent.self))` was not loaded!")
            }
        }
        set {
            id = newValue.id
            value = newValue
        }
    }
    
    /// The projected value of this property wrapper is itself. Used
    /// for when a reference to the _relationship_ type is needed,
    /// such as during eager loads.
    public var projectedValue: Child.BelongsTo<Parent> {
        self
    }
    
    /// Initialize this relationship with an instance of `Parent`.
    ///
    /// - Parameter parent: The `Parent` object to which this child
    ///   belongs.
    public init(wrappedValue: Parent) {
        do {
            value = try Parent.from(wrappedValue)
            id = value?.id
        } catch {
            fatalError("Error initializing `BelongsTo`; expected a value but got nil. Perhaps this relationship should be optional?")
        }
    }
    
    // MARK: Relationship
    
    public static func defaultConfig() -> RelationshipMapping<From, To.Value> {
        return .defaultBelongsTo()
    }
    
    public func set(values: [To]) throws {
        self.wrappedValue = try To.from(values.first)
    }
    
    // MARK: Codable
    
    public func encode(to encoder: Encoder) throws {
        if !(encoder is SQLEncoder) {
            try value.encode(to: encoder)
        } else {
            // When encoding to the database, just encode the Parent's ID.
            var container = encoder.singleValueContainer()
            try container.encode(id)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            id = nil
        } else {
            let parent = try Parent(from: decoder)
            id = parent.id
            value = parent
        }
    }
    
    init(from sqlValue: SQLValue?) throws {
        id = try sqlValue.map { try Parent.Value.Identifier.init(value: $0) }
    }
}

extension BelongsToRelationship: Equatable {
    public static func == (lhs: BelongsToRelationship<Child, Parent>, rhs: BelongsToRelationship<Child, Parent>) -> Bool {
        lhs.id == rhs.id
    }
}
