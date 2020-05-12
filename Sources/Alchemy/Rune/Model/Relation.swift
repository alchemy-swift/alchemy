/// Relationships.
extension Model {
    public typealias OneToOne<To: RelationAllowed> = _OneToOne<Self, To>
    public typealias OneToMany<To: RelationAllowed> = _OneToMany<Self, To>
    public typealias ManyToOne<To: RelationAllowed> = _ManyToOne<Self, To>
    public typealias ManyToMany<To: RelationAllowed> = _ManyToMany<Self, To>
}

@propertyWrapper
/// Either side of a one to one.
public struct _OneToOne<From: RelationAllowed, To: RelationAllowed>: Codable {
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
}

@propertyWrapper
/// The child of a one to many.
public struct _ManyToOne<Many: RelationAllowed, One: RelationAllowed>: Codable {
    public var id: One.Value.Identifier?
    
    public var wrappedValue: One {
        get { fatalError() }
        set { fatalError() }
    }
    
    public init(_ one: One.Value) {
        self.id = one.id
    }
    
    public var projectedValue: Self<Many, One> {
        self
    }
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
}
