/// A type erased `HasRelationship`. Used for special casing decoding
/// behavior for `HasMany` or `HasOne`s.
protocol AnyHas {}

/// A type erased `BelongsToRelationship`. Used for special casing
/// decoding behavior for `BelongsTo`s.
protocol AnyBelongsTo {
    var idValue: SQLValue? { get }
    
    init(from sqlValue: SQLValue?) throws
}
