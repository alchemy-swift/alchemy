/// Conform a class to `Containerized` lets the `@Inject` property wrapper know that there is a
/// custom container from which services should be resolved. If the enclosing type of the property
/// wrapper is not `Containerized`, injected services will be resolved from `Container.global`.
///
/// Usage:
/// ```
/// class UsersController: Containerized {
///     let container = Container()
///
///     // Will be resolved from `self.container` instead of `Container.global`
///     @Inject var database: Database
/// }
/// ```
public protocol Containerized: class {
    /// The container from which `@Inject`ed services on this type should be resolved.
    var container: Container { get }
}

@propertyWrapper
/// Provides a convenient `@propertyWrapper` for injecting services to a type. By default, resolves
/// services from the global container (`Container.global`) but if the enclosing type conforms to
/// `Containerized` services are resolved from `EnclosingType.container`.
public class Inject<Service> {
    /// An optional identifier that may be associated with the service this property wrapper is
    /// injecting. Used for storing any identifiers of a `MultitonService`.
    var identifier: AnyHashable?
    
    /// This should never be called; `subscript` should intercept all calls through here.
    public var wrappedValue: Service {
        get { fatalError("This should never be called.") }
        set { fatalError("This should never be called.") }
    }
    
    /// Create the property wrapper with no identifier.
    public init() {}
    
    /// Resolves an instance of `Service` from the given container.
    ///
    /// - Parameter container: the container to resolve a `Service` from.
    /// - Returns: an instance of `Service` resolved from `container`.
    private func resolve(in container: Container) -> Service {
        container._resolve(Service.self, identifier: self.identifier)!
    }
    
    /// Leverages an undocumented `Swift` API for accessing the enclosing type of a property
    /// wrapper to detect if the enclosing type is `Containerized` and then use that container for
    /// resolving when the `wrappedValue` of the property wrapper is accessed.
    public static subscript<EnclosingSelf>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Service>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Inject<Service>>
    ) -> Service {
        get {
            let customContainer = (object as? Containerized)?.container
            return object[keyPath: storageKeyPath].resolve(in: customContainer ?? .global)
        }
        set {
            // This setter is needed so that the propert wrapper will have a `WritableKeyPath` for
            // using this subscript.
            fatalError("Services should not be set.")
        }
    }
}
