public final class Container {
    static var global = Container()
    
    var storage: [String: FusableResolver] = [:]
    
    private func register<T: IdentifiedService>(singleton: T, identifier: T.Identifier) throws {
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
    private func register<T: SingletonService>(singleton: T) throws {
        let key = self.key(for: T.self)
        guard self.storage[key] == nil else {
            throw FusionError.serviceAlreadyRegistered
        }
        self.storage[key] = SingletonResolver(value: singleton)
    }

    // This closure will be called each time a service is "Fused" with `@Inject`.
    private func register<T: FactoryService>(factory: @escaping (Container) throws -> T) throws {
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
    
    public func resolve<T: IdentifiedService>(_ type: T.Type = T.self, identifier: T.Identifier) throws -> T {
        let key = self.key(for: T.self)
        guard let value = self.storage[key] else {
            let singleton = try T.singleton(in: self, for: identifier)
            try self.register(singleton: singleton, identifier: identifier)
            return singleton
        }
        
        return try value.getTypedValue(for: identifier)
    }
    
    public func resolve<T: SingletonService>(_ type: T.Type = T.self) throws -> T {
        let key = self.key(for: type)
        guard let value = self.storage[key] else {
            let singleton = try T.singleton(in: self)
            try self.register(singleton: singleton)
            return singleton
        }
        
        return try value.getTypedValue(for: nil)
    }
    
    public func resolve<T: FactoryService>(_ type: T.Type = T.self) throws -> T {
        let key = self.key(for: type)
        guard let value = self.storage[key] else {
            let factory = T.factory
            try self.register(factory: factory)
            return try factory(self)
        }
        
        return try value.getTypedValue(for: nil)
    }
    
    private func key<T: Fusable>(for type: T.Type) -> String {
        String(reflecting: type)
    }
}
