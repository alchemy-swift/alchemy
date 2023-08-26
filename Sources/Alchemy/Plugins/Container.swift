import Fusion

extension Container {

    // MARK: KeyPath APIs

    public func get<Base, Type>(_ key: KeyPath<Base, Type>) -> Type? {
        resolve(id: key)
    }

    public func require<Base, Type>(_ key: KeyPath<Base, Type>, error: StaticString? = nil) -> Type {
        guard let value = resolve(Type.self, id: key) else {
            preconditionFailure(error?.description ?? "Cannot get extension of type \(Type.self) without having set it")
        }

        return value
    }

    public func exists<Base, Type>(_ key: KeyPath<Base, Type>) -> Bool {
        resolve(Type.self, id: key) != nil
    }

    public func set<Base, Type>(_ key: KeyPath<Base, Type>, value: Type) {
        registerSingleton(value, id: key)
    }

    // MARK: Convenience APIs

    public func registerSingleton<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self, id: AnyHashable? = nil) {
        bind(.singleton, to: type, id: id, value: value())
    }

    public func register<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self) {
        bind(.transient, to: type, value: value())
    }

    public func register<T>(_ value: @escaping (Container) -> T, as type: T.Type = T.self) {
        bind(.transient, to: type, value: value(self))
    }
}

extension Application {
    /// The main application container.
    public var container: Container { .main }
}
