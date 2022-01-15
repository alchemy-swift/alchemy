public protocol Extendable {
    var extensions: Extensions<Self> { get }
}

public final class Extensions<ParentObject> {
    private var items: [PartialKeyPath<ParentObject>: Any]
    
    /// Initialize extensions
    public init() {
        self.items = [:]
    }

    /// Get optional extension from a `KeyPath`
    public func get<Type>(_ key: KeyPath<ParentObject, Type>) -> Type? {
        self.items[key] as? Type
    }
    
    /// Get extension from a `KeyPath`
    public func get<Type>(_ key: KeyPath<ParentObject, Type>, error: StaticString? = nil) -> Type {
        guard let value = items[key] as? Type else {
            preconditionFailure(error?.description ?? "Cannot get extension of type \(Type.self) without having set it")
        }
        return value
    }
    
    /// Return if extension has been set
    public func exists<Type>(_ key: KeyPath<ParentObject, Type>) -> Bool {
        self.items[key] != nil
    }

    /// Set extension for a `KeyPath`
    /// - Parameters:
    ///   - key: KeyPath
    ///   - value: value to store in extension
    public func set<Type>(_ key: KeyPath<ParentObject, Type>, value: Type) {
        items[key] = value
    }
}
