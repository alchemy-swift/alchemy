import Foundation

extension Model {
    public typealias Relation<To: RelationAllowed> = _Relation<Self, To>
}

/// So that `[Model]` & `Model` can have similar functionality
public protocol RelationAllowed {
    associatedtype Value: Model
    var elementType: Value.Type { get }
}

extension RelationAllowed {
    public var elementType: Self.Type { Self.self }
}

extension Array: RelationAllowed where Element: Model {
    public var elementType: Element.Type { Element.self }
}

extension Optional: RelationAllowed where Wrapped: Model {
    public var elementType: Wrapped.Type { Wrapped.self }
}

@propertyWrapper
public struct _Relation<From: RelationAllowed, To: RelationAllowed>: Codable {
    public var wrappedValue: To {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }

    public init(_ to: To) {

    }

    public init() {
        
    }

    public init(builder: (From.Value.Relation<From.Value>) -> From.Value.Relation<To.Value>) {

    }

    public init(viaTheirKey: KeyPath<To.Value, From.Value>) {

    }

    public init(viaTheirKey: KeyPath<To.Value, From.Value?>) {

    }

    public init(viaJunction: JunctionTable<From.Value, To.Value>) {

    }

    public var projectedValue: _Relation<From, To> {
        self
    }
}

public struct ModelTable: Table {
    public var name: String = "compute this"
    public var fields: [String] = []
}

extension Model {
    public static var table: ModelTable {
        ModelTable()
    }

//    public static func query(_ database: Database = Database.default) -> Query {
//        return Query(database: database).from(table: self.table)
//    }

    public static func all() -> Future<[Self]> {
        Future([])
    }
}

// Name for this? "Association Table"? "Linking Table"?
public struct JunctionTable<T: Model, U: Model>: Table {
    public var fields: [String] = []

    // We need an identifier, right?
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
}

public protocol Model: Identifiable, RelationAllowed, Table { }

public struct Future<T> {
    public init(_ val: T) {

    }
}

// MARK: - Eager Loading

// MARK: - CRUD on Relations

// MARK: - Touching & Timestamps

// MARK: - Relation vs Query
/// Make `Relation` a subset of Query for similar lazy loading behavior, but extended functionality such as
/// add, delete, touch, etc.
