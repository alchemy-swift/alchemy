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
    init(from row: SQLRow) // Auto filled in for codable models, in extension
    func toSQLRow() -> SQLRow // Auto filled in for codable models, in extension
}

// For custom logic around attributes (ENUM, JSON, relationship, encrypted, filename, etc)
// then thin out decoder / encoder to check for this type and that's it? Then
// conform all types. Make it easy to add new types. What about arrays?
//
// Storing `null`?
protocol ModelAttribute {
    init(field: SQLField)
    func store(at key: String) -> SQLField
}

// CreatedAt updated at?

// Appendable to a `ModelQuery`; async throw runs on results before returning.
protocol EagerLoadable {
    // Also need the SQL rows? Since need to find value based on column key.
    // Not quite right; need to set on models individually. Can just get rows
    // and leave the setting to the caller who has KP access?
    static func load(values: [SQLRow]) async throws -> [Self]
}

// Relationship crud is a separate beast; all queries on the relationship.
// user.$todos.append(moreTodos)
protocol Relationship2 {
    func get() // load in this case?
    func add() // adds one or more
    func remove() // removes the given ones
    func update() // updates to the given ones? might be tricky
}

protocol ModelProperty {
    // Initialize from a field.
    init(field: SQLField)
    
    // Store as field.
    func store() async throws
}

protocol EagerLoadable: ModelProperty {
    // Eager loads this model, if it needs it.
    func load(values: [SQLRow]) async throws
}

struct SQLField {
    let column: String
    let value: SQLValue
}
