/// The caching behavior, per container, for a factory.
private enum ResolveBehavior {
    /// A new instance should be created once per container.
    case singleton
    /// A new instance should be created at every `.resolve(...)`.
    case transient
}

/// A container from which services should be registered and resolved.
public final class Container {
    /// Generic factory closure. A container and an optional identifier are passed in and a service
    /// is generated.
    private typealias FactoryClosure = (Container, Any?) -> Any
    
    /// A global, singleton container.
    public static var global = Container()
    
    /// The parent container of this container. Resolves that don't have a value in this container
    /// will be deffered to the parent container.
    private var parent: Container?
    
    /// Any cached instances of services held in this container (used for singletons and multitons)
    private var instances: [String: Any] = [:]
    
    /// The resolvers registered to this container. Each resolver has a factory closure and behavior
    /// by which the values are cached or not.
    private var resolvers: [String: (behavior: ResolveBehavior, factory: FactoryClosure)] = [:]
    
    /// Initialize a container with an optional parent `Container`.
    ///
    /// - Parameter parent: the optional parent `Container`. Defaults to nil.
    public init(parent: Container? = nil) {
        self.parent = parent
    }
    
    /// Register a transient service to this container. Transient means that it's factory closure
    /// will be called _each time_ the service type is resolved.
    ///
    /// - Parameters:
    ///   - service: the type of the service to register.
    ///   - factory: the closure for instantiating an instance of the service.
    public func register<T>(_ service: T.Type, factory: @escaping (Container) -> T) {
        let key = self.storageKey(for: service, identifier: nil)
        self.resolvers[key] = (.transient, { container, _ in
            factory(container)
        })
    }
    
    /// Register a singleton service to this container. Singleton means that it's factory closure
    /// will be called _once_ and that value will be returned each time the service is resolved.
    ///
    /// - Parameters:
    ///   - service: the type of the service to register.
    ///   - factory: the closure for instantiating an instance of the service.
    public func register<S>(singleton service: S.Type, factory: @escaping (Container) -> S) {
        let key = self.storageKey(for: service, identifier: nil)
        self.resolvers[key] = (.singleton, { container, _ in
            factory(container)
        })
    }
    
    /// Register a identified singleton service to this container. Singleton means that it's factory
    /// closure will be called _once_ per unique identifier and that value will be returned each
    /// time the service is resolved.
    ///
    /// - Parameters:
    ///   - service: the type of the service to register.
    ///   - factory: the closure for instantiating an instance of the service.
    public func register<S, H: Hashable>(
        singleton service: S.Type,
        identifier: H,
        factory: @escaping (Container) -> S
    ) {
        let key = self.storageKey(for: service, identifier: identifier)
        self.resolvers[key] = (.singleton, { container, _ in
            factory(container)
        })
    }
    
    /// Resolves a service, returning an instance of it, if one is registered.
    ///
    /// - Parameter service: the type of the service to resolve.
    /// - Returns: an instance of the service.
    public func resolveOptional<T>(_ service: T.Type) -> T? {
        self._resolve(service, identifier: nil)
    }
    
    /// Resolves a service with the given `identifier`, returning an instance of it if one is
    /// registered.
    ///
    /// - Parameter service: the type of the service to resolve.
    /// - Parameter identifier: the identifier of the service to resolve.
    /// - Returns: an instance of the service.
    public func resolveOptional<T, H: Hashable>(_ service: T.Type, identifier: H?) -> T? {
        self._resolve(service, identifier: identifier)
    }
    
    /// Resolves a service, returning an instance of it.
    ///
    /// This will `fatalError` if the service isn't registered.
    ///
    /// - Parameter service: the type of the service to resolve.
    /// - Returns: an instance of the service.
    public func resolve<T>(_ service: T.Type) -> T {
        self.assertNotNil(self._resolve(service, identifier: nil))
    }
    
    /// Resolves a service with the given `identifier`, returning an instance of it.
    ///
    /// This will `fatalError` if the service isn't registered.
    ///
    /// - Parameter service: the type of the service to resolve.
    /// - Parameter identifier: the identifier of the service to resolve.
    /// - Returns: an instance of the service.
    public func resolve<T, H: Hashable>(_ service: T.Type, identifier: H?) -> T {
        self.assertNotNil(self._resolve(service, identifier: identifier))
    }
    
    /// Resolves a generic service with an optional identifier.
    ///
    /// Internal for usage in the `Inject` property wrapper.
    ///
    /// - Parameters:
    ///   - service: the type of the service to resolve.
    ///   - identifier: an optional identifier that may be associated with this service.
    /// - Returns: an instance of the service, if it is able to be resolved by this `Container` or
    ///            it's parents.
    func _resolve<T>(_ service: T.Type, identifier: AnyHashable?) -> T? {
        let key = self.storageKey(for: service, identifier: identifier)
        if let instance = self.instances[key] {
            return self.assertType(of: instance)
        } else if let resolver = self.resolvers[key] {
            let instance: T = self.assertType(of: resolver.factory(self, identifier))
            if resolver.behavior == .singleton {
                self.instances[key] = instance
            }
            return instance
        } else if let instance = self.parent?._resolve(service, identifier: identifier) {
            return instance
        }
        return nil
    }
    
    /// A key for local storage of instances and factories of services. It's the type name & the
    /// hash value of the identifier (if there is one), separated by an underscore.
    ///
    /// - Parameters:
    ///   - service: the service type to generate a key for.
    ///   - identifier: any identifier that
    /// - Returns: a string for keying the dictionaries that may hold instances or factories
    ///            associated with the service type.
    private func storageKey<T>(for service: T.Type, identifier: AnyHashable?) -> String {
        var base = "\(service)"
        if let identifier = identifier {
            base += "_\(identifier.hashValue)"
        }
        return base
    }
    
    /// Asserts that an optional value is not nil. If it is nil, a fatal error occurs.
    ///
    /// - Parameter value: the value to check for nil.
    /// - Returns: the unwrapped value `T`.
    private func assertNotNil<T>(_ value: T?) -> T {
        guard let unwrapped = value else {
            fatalError("Unable to resolve service of type \(T.self)! Perhaps it isn't registered?")
        }
        
        return unwrapped
    }
    
    /// Asserts that an instance matches another type. If it does not, a fatal error occurs.
    ///
    /// - Parameters:
    ///   - instance: the instance to check the type of.
    ///   - equals: the type to ensure `instance` conforms to.
    /// - Returns: the instance cast to `U` if the conversion was successful.
    private func assertType<T, U>(of instance: T, equals: U.Type = U.self) -> U {
        guard let instance = instance as? U else {
            fatalError("Internal storage type mismatch.")
        }
        
        return instance
    }
}
