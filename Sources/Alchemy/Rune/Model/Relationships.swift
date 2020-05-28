import Foundation

/// Relationships.
extension Model {
    public typealias OneToOne<To: RelationAllowed> = _OneToOne<Self, To>
    public typealias OneToMany<To: RelationAllowed> = _OneToMany<Self, To>
    public typealias ManyToOne<To: RelationAllowed> = _ManyToOne<Self, To>
    public typealias ManyToMany<To: RelationAllowed> = _ManyToMany<Self, To>
}

protocol Relationship {
    associatedtype To: RelationAllowed
    
    init(value: To.Value)
}

protocol AnyOneToOne {}

@propertyWrapper
/// Either side of a one to one.
public struct _OneToOne<From: RelationAllowed, To: RelationAllowed>: Codable, AnyOneToOne {
    public var id: To.Value.Identifier?
    
    public var wrappedValue: To {
        get { fatalError() }
        set { fatalError() }
    }
    
    /// Parent init
    public init(to: KeyPath<To, From>) {
        
    }
    
    /// Child init
    public init(to: To.Value) {
        self.id = to.id
    }
    
    public var projectedValue: Self<From, To> {
        self
    }
    
    public func encode(to encoder: Encoder) throws {
        /// If this holds a reference to another object, encode it.
        if let id = self.id {
            var container = encoder.singleValueContainer()
            try container.encode(id)
        }
    }
}

@propertyWrapper
/// The parent of a one to many.
public struct _OneToMany<One: RelationAllowed, Many: RelationAllowed>: Codable {
    public var wrappedValue: [Many] {
        get { fatalError() }
        set { fatalError() }
    }
    
    public init(to: KeyPath<Many, One>) {
        
    }
    
    public var projectedValue: Self<One, Many> {
        self
    }
    
    public func encode(to encoder: Encoder) throws {
        /// Do nothing.
    }
}

protocol AnyManyToOne {}

@propertyWrapper
/// The child of a one to many.
public struct _ManyToOne<Many: RelationAllowed, One: RelationAllowed>: Codable, AnyManyToOne {
    public var id: One.Value.Identifier
    
    public var wrappedValue: One {
        get { fatalError() }
        set { fatalError() }
    }
    
    public init(_ one: One.Value) {
        guard let id = one.id else {
            fatalError("Can't form a relation with an unidentified object.")
        }

        self.id = id
    }
    
    public var projectedValue: Self<Many, One> {
        self
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
    
//    public init(from decoder: Decoder) throws {
//
//    }
}

@propertyWrapper
/// Either side of a many to many.
public struct _ManyToMany<From: RelationAllowed, To: RelationAllowed>: Codable {
    public var wrappedValue: [To] {
        get { fatalError() }
        set { fatalError() }
    }
    
    public init<M: Model>(
        viaModel: M.Type = M.self,
        from fromKeyPath: KeyPath<M, From.Value>,
        to toKeyPath: KeyPath<M, To.Value>)
    {

    }
    
    public var projectedValue: Self<From, To> {
        self
    }
    
    public func encode(to encoder: Encoder) throws {
        /// Do nothing.
    }
}
