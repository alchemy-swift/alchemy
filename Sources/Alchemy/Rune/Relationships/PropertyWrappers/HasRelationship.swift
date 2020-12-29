import NIO

/// A type erased `HasRelationship`. Used for special casing decoding behavior for `HasMany` or
/// `HasOne`s.
protocol AnyHas {}

/// Contains shared behavior for "has" relationships, particularly around eager loading
/// functionality.
///
/// - Warning: Eager loading for `HasRelationship`s is a janky mess since there isn't a good way to
/// associate data with a property wrapper that persists when the `Model` is encoded / decoded.
///
/// It does work though :)
public class HasRelationship<From: Model, To: ModelMaybeOptional>: AnyHas, Decodable {
    /// Erased behavior for how to eager load this relationship.
    var eagerLoadClosure: NestedEagerLoadClosure<From, To>!
    
    /// Initializes this relationship as a 1 - M. This assumes that there is a key on the `To` table
    /// that has a reference to `From.id`.
    ///
    /// - Parameters:
    ///   - this: a unique name for this. The name must be unique on a `From` / `To` type basis.
    ///           i.e. for each relationship to `To` on type `From`, there must be a unique name.
    ///           This is an implementation detail leaking out, sorry another way hasn't been found.
    ///   - key: the `KeyPath` of the relationship on `To` that points to `From`.
    ///   - keyString: the string name of the column on `To` that points to `From`'s id.
    public required init(
        this: String,
        to key: KeyPath<To.Value, To.Value.BelongsTo<From>>,
        keyString: String
    ) {
        self.eagerLoadClosure = { EagerLoader<From, To>.via(key: key, keyString: keyString, nestedQuery: $0!) }
        
        EagerLoadStorage.store(
            from: From.self,
            to: To.self,
            fromStored: this,
            loadClosure: self.eagerLoadClosure
        )
    }
    
    /// Initializes this relationship as a M - M. This assumes that there is a pivot table with
    /// columns representing the primary keys of both `From` and `To`.
    ///
    /// - Parameters:
    ///   - named: a unique name for this. The name must be unique on a `From` / `To` type basis.
    ///             i.e. for each relationship to `To` on type `From`, there must be a unique name.
    ///             This is an implementation detail leaking out, sorry another way hasn't been
    ///             found.
    ///   - fromKey: the `KeyPath` on the pivot table that points to the `From` type in the
    ///              relationship.
    ///   - toKey: the `KeyPath` on the pivot table that points to the `To` type in the
    ///            relationship.
    ///   - fromString: the column name on the pivot table that references the `From` table's id.
    ///   - toString: the column name on the pivot table that references the `To` table's id.
    public required init<Through: Model>(
        named: String,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String
    ) {
        self.eagerLoadClosure = {
            EagerLoader<From, To>.through(
                named: named,
                from: fromKey,
                to: toKey,
                fromString: fromString,
                toString: toString,
                nestedQuery: $0
            )
        }

        EagerLoadStorage.store(
            from: From.self,
            to: To.self,
            fromStored: named,
            loadClosure: self.eagerLoadClosure
        )
    }
    
    // MARK: Decodable
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingKey = try container.decode(String.self)
        
        guard let loadClosure = EagerLoadStorage.get(
                from: From.self,
                to: To.self,
                fromStored: codingKey
            ) else { fatalError("Unable to find the data of this relationship ;_;") }
        
        self.eagerLoadClosure = loadClosure
    }
}
