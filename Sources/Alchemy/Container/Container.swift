import Fusion

extension Container {
    func registerSingleton<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self, id: AnyHashable? = nil) {
        bind(.singleton, to: type, identifier: id, value: value())
    }

    func register<T>(_ value: @escaping @autoclosure () -> T, as type: T.Type = T.self) {
        bind(.transient, to: type, value: value())
    }

    func register<T>(_ value: @escaping (Container) -> T, as type: T.Type = T.self) {
        bind(.transient, to: type, value: value(self))
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
