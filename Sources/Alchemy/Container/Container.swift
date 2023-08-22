import Fusion

extension Container {

    // Simple Registration

    func registerSingleton<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self, id: AnyHashable? = nil) {
        bind(.singleton, to: type, id: id, value: value())
    }

    func register<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self) {
        bind(.transient, to: type, value: value())
    }

    func register<T>(_ value: @escaping (Container) -> T, as type: T.Type = T.self) {
        bind(.transient, to: type, value: value(self))
    }

    // Key Paths

    /// Get optional extension from a `KeyPath`
    public func get<Base, Type>(_ key: KeyPath<Base, Type>) -> Type? {
        resolve(id: key)
    }

    /// Get extension from a `KeyPath`
    public func get<Base, Type>(_ key: KeyPath<Base, Type>, error: StaticString? = nil) -> Type {
        guard let value = resolve(Type.self, id: key) else {
            preconditionFailure(error?.description ?? "Cannot get extension of type \(Type.self) without having set it")
        }

        return value
    }

    /// Return if extension has been set
    public func exists<Base, Type>(_ key: KeyPath<Base, Type>) -> Bool {
        resolve(Type.self, id: key) != nil
    }

    /// Set extension for a `KeyPath`
    /// - Parameters:
    ///   - key: KeyPath
    ///   - value: value to store in extension
    public func set<Base, Type>(_ key: KeyPath<Base, Type>, value: Type) {
        registerSingleton(value, id: key)
    }
}

extension Application {
    public var container: Container { .main }

    public func registerSingleton<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self, id: AnyHashable? = nil) {
        container.registerSingleton(value(), as: type, id: id)
    }

    public func register<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self) {
        container.register(value(), as: type)
    }

    public func register<T>(_ value: @escaping (Container) -> T, as type: T.Type = T.self) {
        container.register(value, as: type)
    }
}
