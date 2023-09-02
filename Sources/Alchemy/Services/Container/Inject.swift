/// Provides a convenient `@propertyWrapper` for injecting services to a type.
/// By default, resolves services from the global container (`Container.main`)
/// but if the enclosing type conforms to `Containerized` services are
/// resolved from `EnclosingType.container`.
@propertyWrapper
public final class Inject<Value> {
    /// The value is injected each time this is accessed.
    public var wrappedValue: Value {
        get { Container.main.require(id: id) }
    }

    /// An optional identifier that may be associated with the service this
    /// property wrapper is injecting. Used for storing any identifiers 
    /// of a service.
    private var id: AnyHashable?

    /// Create the property wrapper with an identifier.
    public init(id: AnyHashable? = nil) {
        self.id = id
    }

    public convenience init(_ id: AnyHashable? = nil) {
        self.init(id: id)
    }

    // MARK: Containerized Support

    /// Resolves the value, resolving from the specified container if
    /// `EnclosingSelf` is `Containerized`.
    public static subscript<EnclosingSelf>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: KeyPath<EnclosingSelf, Inject<Value>>
    ) -> Value {
        let container = (object as? Containerized)?.container ?? .main
        return container.require(id: object[keyPath: storageKeyPath].id)
    }
}
