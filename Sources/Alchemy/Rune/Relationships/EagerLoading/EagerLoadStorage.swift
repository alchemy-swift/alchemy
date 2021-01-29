import Foundation

/// Each `HasRelationship` stores an erased closure of how it eager
/// loads it's values. Unfortunately it's difficult to persist this
/// closure as `Model`s are decoded from the database. This class is a
/// cache of relationship names -> eager load closures, so they can be
/// properly associated when the `Model` is decoded.
///
/// There needs to be a better way of doing this because of the weird
/// implementation details leaking out (unique id for each has
/// relationship), thread safety issues (all event loops need to
/// access this object, etc). Some options are...
/// 1. Keep eager loading behavior in the property wrapper & figure
///    out how to initialize a generic `Model` without decoding (so
///    the data in the property wrapper is available), then pull it
///    with the KeyPaths passed to `.with(...)` when eager loading.
/// 2. Remove eager loading behavior from the property wrapper
///    initializer. Instead have each relationship type have default
///    assumed eager load behavior but give the user the option to
///    have custom behavior in a
///    `static var eagerLoadingBehavior: [KeyPath: EagerLoadBehavior]`
///    on the Model.
///
/// 1 would be best, since the behavior should be tied to the
/// relationship, but I don't think it will be possible to initialize
/// without losing the info in the default propertyWrapper
/// initializer, so 2 will likely need to be the way moving forward.
///
/// Also, the only reason this works is because when initializing
/// property wrappers from a decoder, for some reason the provided
/// init is called before the decoder init is called, giving us a
/// chance to cache the eager load closure if it hasn't been already.
final class EagerLoadStorage {
    /// Threadsafe dict for mapping relationship names to their erased
    /// eager loading closure.
    @Locked
    private static var dict: [String: Any] = [:]
    
    /// Store an erased eager loading closure in a lookup dictionary.
    static func store<From: Model, To: ModelMaybeOptional>(
        relationship: HasRelationship<From, To>.Type,
        uniqueKey: String?,
        loadClosure: @escaping NestedEagerLoadClosure<From, To>
    ) {
        let id = uniqueKey ?? "default"
        let key = "\(relationship)_\(id)"
        dict[key] = loadClosure
    }
    
    /// Fetch an erased eager loading closure from the lookup
    /// dictionary.
    static func get<From: Model, To: ModelMaybeOptional>(
        relationship: HasRelationship<From, To>.Type,
        uniqueKey: String
    ) -> NestedEagerLoadClosure<From, To>? {
        let key = "\(relationship)_\(uniqueKey)"
        let fallback = "\(relationship)_default"
        return dict[key] as? NestedEagerLoadClosure<From, To>
            ?? dict[fallback] as? NestedEagerLoadClosure<From, To>
    }
}
