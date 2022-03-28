/// A type erased `HasRelationship`. Used for special casing decoding
/// behavior for `HasMany` or `HasOne`s.
protocol AnyHas {}

/// A type erased `BelongsToRelationship`. Used for special casing
/// decoding behavior for `BelongsTo`s.
protocol AnyBelongsTo {
    var idValue: SQLValue? { get }
    
    init(from sqlValue: SQLValue?) throws
}

/*
 Eager Loading
 1. Some model properties may store something in an SQL row that's a hook for
    another object.
    a. `BelongsTo` stores id, eager loads other `Model`
    b. `Store` stores url, eager loads `File`
    c. custom, load from SQValue & column, store as `SQLValue` at `String`
    d. should all fields be ModelProperty? no; couldn't do multipler arrays.
 2.
 */

/*
 Use cases
 1. Relationships (Single, Optional, Array, Store / Don't Store)
 2. Encryption
 3. File on model
 4. Image as blob
 5. Custom
 6. Convert JSON to Array
 7. Custom JSON storage
 8. Convert custom property; such as date using specific format. (in initializer)
 9. Async operations on the wrapper itself
 */

/*
 Relationship CRUD
 1. On relationship object itself. Each defines method for get / add / update / delete
 */

// Protocol
// 1. Store value in db
// 2. Load value from db
// Eager loading?
// - run complicated work on batches of data so it's simpler... only applies to
//   relationships? Could easily be custom done? Add a "run after query"
//   protocol? Custom map; take results and do something to them.

protocol Model2 {
    init(row: SQLRow) throws // Auto filled in for codable models, in extension
    func toSQLRow() throws -> SQLRow // Auto filled in for codable models, in extension
}

// Appendable to a `ModelQuery`; async throw runs on results before returning.
protocol EagerLoadableProperty: ModelProperty {
    // Downside;
    // 1. Must be in order
    // 2. Must be same length
    static func load(values: [PartialLoad<Self>]) async throws -> [Self]
}

struct PartialLoad<T: EagerLoadableProperty> {
    let row: SQLRow
    let initialValue: T
}

// Relationship crud is a separate beast; all queries on the relationship.
// user.$todos.append(moreTodos)
protocol Relationship2: EagerLoadableProperty {
    associatedtype From: Model
    associatedtype To: Model
    
    var mapping: RelationshipMapping<To, From> { get }
    
    func get() -> To // load in this case?
    func add() // adds one or more
    func remove() // removes the given ones
    func update() // updates to the given ones? might be tricky
}

protocol Timestamps {
    // Might not need to require these? Can just update SQLRow.
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}
