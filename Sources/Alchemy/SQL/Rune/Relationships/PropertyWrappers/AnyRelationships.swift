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
