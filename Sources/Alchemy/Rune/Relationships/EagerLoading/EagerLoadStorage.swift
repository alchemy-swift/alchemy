import Foundation

/// Each `HasRelationship` stores an erased closure of how it eager loads it's values. Unfortunately
/// it's difficult to persist this closure as `Model`s are decoded from the database. This class
/// is a cache of relationship names -> eager load closures, so they can be properly associated when
/// the `Model` is decoded.
///
/// There needs to be a better way of doing this because of the weird implementation details leaking
/// out (unique id for each has relationship), thread safety issues (all event loops need to access
/// this object, etc). Some options are...
/// 1. Keep eager loading behavior in the property wrapper & figure out how to initialize a generic
///    Model without decoding (so the data in the property wrapper is available), then pull it with
///    the KeyPaths passed to `.with(...)` when eager loading.
/// 2. Remove eager loading behavior from the property wrapper initializer. Instead have each
///    relationship type have default assumed eager load behavior but give the user the option to
///    have custom behavior in a `static var eagerLoadingBehavior: [KeyPath: EagerLoadBehavior]` on
///    the Model.
///
/// 1 would be best, since the behavior should be tied to the relationship, but I don't think it
/// will be possible to initialize without losing the info in the default propertyWrapper
/// initializer, so 2 will likely need to be the way moving forward.
final class EagerLoadStorage {
    /// Lock for keeping static access of this property threadsafe.
    private static let lock = NSRecursiveLock()
    
    /// A dict for mapping relationship names to their erased eager loading closure. Accessing this
    /// is threadsafe.
    private static var dict: [String: Any] {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self._dict
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self._dict = newValue
        }
    }
    
    /// Underlying dict for which `dict` provides a thread safe setter & getter.
    private static var _dict: [String: Any] = [:]

    /// Store an erased eager loading closure in a lookup dictionary.
    static func store<From: Model, To: ModelMaybeOptional>(
        from: From.Type = From.self,
        to: To.Type = To.self,
        fromStored: String,
        loadClosure: @escaping NestedEagerLoadClosure<From, To>
    ) {
        let key = "\(From.tableName)_\(To.Value.tableName)_\(fromStored)"
        dict[key] = loadClosure
    }
    
    /// Fetch an erased eager loading closure from the lookup dictionary.
    static func get<From: Model, To: ModelMaybeOptional>(
        from: From.Type,
        to: To.Type,
        fromStored: String
    ) -> NestedEagerLoadClosure<From, To>? {
        let key = "\(From.tableName)_\(To.Value.tableName)_\(fromStored)"
        return dict[key] as? NestedEagerLoadClosure<From, To>
    }
}
