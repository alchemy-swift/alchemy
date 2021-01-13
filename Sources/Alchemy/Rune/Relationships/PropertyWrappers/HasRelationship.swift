import NIO

/// A type erased `HasRelationship`. Used for special casing decoding
/// behavior for `HasMany` or `HasOne`s.
protocol AnyHas {}

/// Contains shared behavior for "has" relationships, particularly
/// around eager loading functionality.
public class HasRelationship<From: Model, To: ModelMaybeOptional>: AnyHas, Decodable {
    /// Erased behavior for how to eager load this relationship.
    var eagerLoadClosure: NestedEagerLoadClosure<From, To>!
    
    /// Initializes this relationship as a 1 - M. This assumes that
    /// there is a key on the `To` table that has a reference to
    /// `From.id`.
    ///
    /// - Parameters:
    ///   - this: The name of this property. The name must be unique
    ///     on a `From` / `To` type basis. i.e. for each
    ///     relationship to `To` on type `From`, there must be a
    ///     unique name. This is an implementation detail leaking out,
    ///     sorry another way hasn't been found.
    ///   - key: The `KeyPath` of the relationship on `To` that points
    ///     to `From`.
    ///   - keyString: The string name of the column on `To` that
    ///     points to `From`'s id.
    public required init(
        propertyName: String? = nil,
        to key: KeyPath<To.Value, To.Value.BelongsTo<From>>,
        keyString: String
    ) {
        self.eagerLoadClosure = { EagerLoader<From, To>.via(key: key, keyString: keyString, nestedQuery: $0!) }
        
        EagerLoadStorage.store(
            relationship: Self.self,
            uniqueKey: propertyName,
            loadClosure: self.eagerLoadClosure
        )
    }
    
    /// Initializes this relationship as a M - M. This assumes that
    /// there is a pivot table with columns representing the
    /// primary keys of both `From` and `To`.
    ///
    /// - Parameters:
    ///   - named: A unique name for this. The name must be unique on
    ///     a `From` / `To` type basis. i.e. for each relationship to
    ///     `To` on type `From`, there must be a unique name. This is
    ///     an implementation detail leaking out, sorry another way
    ///     hasn't been found.
    ///   - fromKey: The `KeyPath` on the pivot table that points to
    ///     the `From` type in the relationship.
    ///   - toKey: The `KeyPath` on the pivot table that points to the
    ///     `To` type in the relationship.
    ///   - fromString: The column name on the pivot table that
    ///     references the `From` table's id.
    ///   - toString: The column name on the pivot table that
    ///     references the `To` table's id.
    public required init<Through: Model>(
        propertyName: String? = nil,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String
    ) {
        self.eagerLoadClosure = {
            EagerLoader<From, To>.through(
                from: fromKey,
                to: toKey,
                fromString: fromString,
                toString: toString,
                nestedQuery: $0
            )
        }

        EagerLoadStorage.store(
            relationship: Self.self,
            uniqueKey: propertyName,
            loadClosure: self.eagerLoadClosure
        )
    }
    
    // MARK: Decodable
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingKey = try container.decode(String.self)
        
        guard let loadClosure = EagerLoadStorage.get(
            relationship: Self.self,
            uniqueKey: codingKey
        ) else {
            fatalError("Unable to find a relationship with `property` name `\(codingKey.value)`!")
        }
        
        self.eagerLoadClosure = loadClosure
    }
}
