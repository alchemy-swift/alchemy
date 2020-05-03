public final class Container {
    static var global = Container()
    
    var storage: [String: FusableResolver] = [:]
    
    // This closure will be called once, when the identifier for the service is first registered.
    public func register<T: Fusable>(singleton: T, identifier: String) throws {
        let key = self.key(for: T.self)
        if let existingValue = self.storage[key] {
            guard let existingValue = existingValue as? IdentifiedSingletonResolver else {
                throw FusionError.registeredServiceResolverMismatch
            }

            guard existingValue.values[identifier] == nil else {
                throw FusionError.serviceAlreadyRegistered
            }
            
            self.storage[key] = existingValue.adding(service: singleton, for: identifier)
        } else {
            self.storage[key] = IdentifiedSingletonResolver(values: [identifier: singleton])
        }
    }
    
    // This closure will be called once, when the service is first registered.
    public func register<T: Fusable>(singleton: T) throws {
        let key = self.key(for: T.self)
        guard self.storage[key] == nil else {
            throw FusionError.serviceAlreadyRegistered
        }
        self.storage[key] = SingletonResolver(value: singleton)
    }

    // This closure will be called each time a service is "Fused" with `@Fuse`.
    public func register<T: Fusable>(factory: @escaping (Container) throws -> T) throws {
        let key = self.key(for: T.self)
        guard self.storage[key] == nil else {
            throw FusionError.serviceAlreadyRegistered
        }
        self.storage[key] = FactoryResolver { [weak self] in
            guard let this = self else {
                throw FusionError.containerDeallocated
            }
            
            return try factory(this)
        }
    }
    
    public func resolve<T: Fusable>(_ type: T.Type = T.self, identifier: String? = nil) throws -> T {
        try self.ensureRegistration(of: T.self)
        
        guard let value = self.storage[self.key(for: type)] else {
            throw FusionError.serviceNotRegistered
        }
        
        return try value.getTypedValue(for: identifier)
    }
    
    private func ensureRegistration<T: Fusable>(of type: T.Type) throws {
        let key = self.key(for: T.self)
        guard self.storage[key] == nil else {
            return
        }
        
        try T.register(in: self)
    }
    
    private func key<T: Fusable>(for type: T.Type) -> String {
        String(reflecting: type)
    }
}
