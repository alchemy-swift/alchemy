import Foundation

/// A container from which services are registered and resolved.
public final class Container: CustomDebugStringConvertible {
    public final class Factory {
        fileprivate var scope: Scope
        private let create: (Container) -> Any
        private var cache: Any?

        fileprivate init(_ create: @escaping (Container) -> Any) {
            self.scope = .transient
            self.create = create
            self.cache = nil
        }

        fileprivate func value(in container: Container) -> Any {
            guard let cache else {
                let value = create(container)
                if scope == .singleton { cache = value }
                return value
            }

            return cache
        }

        // MARK: Builders

        public func singleton() {
            self.scope = .singleton
        }
    }

    /// The caching behavior for a factory.
    fileprivate enum Scope: String {
        /// A new instance should be created at every `.resolve(...)`.
        case transient
        /// A new instance should be created once per container.
        case singleton
    }

    fileprivate struct Key: Hashable {
        let typeString: String
        var id: AnyHashable?

        init<T>(type: T.Type, id: AnyHashable? = nil) {
            self.typeString = "\(type)"
            self.id = id
        }

        static func == (lhs: Key, rhs: Key) -> Bool {
            // This way, regardless of the type of the id, if it has the same
            // hashValue (typically because its backed by the same hashable
            // type) it will be equal.
            lhs.hashValue == rhs.hashValue
        }
    }

    /// The main service container.
    public static var main = Container()

    private let parent: Container?
    private let lock: NSRecursiveLock
    private var factories: [Key: Factory]

    /// Initialize a container with an optional parent `Container`.
    ///
    /// - Parameter parent: The optional parent `Container`. Defaults to `nil`.
    public init(parent: Container? = nil) {
        self.parent = parent
        self.lock = NSRecursiveLock()
        self.factories = [:]
    }

    /// Remove all factories and cached values from this container.
    public func reset() {
        lock.withLock {
            factories = [:]
        }
    }

    // MARK: Registering

    @discardableResult
    public func register<T>(factory: @escaping (Container) -> T, id: AnyHashable? = nil) -> Factory {
        lock.withLock {
            let factory = Factory(factory)
            factories[Key(type: T.self, id: id)] = factory
            return factory
        }
    }

    @discardableResult
    public func register<T>(_ factory: @escaping () -> T, id: AnyHashable? = nil) -> Factory {
        register(factory: { _ in factory() }, id: id)
    }

    @discardableResult
    public func register<T>(_ factory: @escaping @autoclosure () -> T, id: AnyHashable? = nil) -> Factory {
        register(factory: { _ in factory() }, id: id)
    }

    @discardableResult
    public static func register<T>(factory: @escaping (Container) -> T, id: AnyHashable? = nil) -> Factory {
        main.register(factory: factory, id: id)
    }

    @discardableResult
    public static func register<T>(_ factory: @escaping () -> T, id: AnyHashable? = nil) -> Factory {
        main.register(factory, id: id)
    }

    @discardableResult
    public static func register<T>(_ factory: @escaping @autoclosure () -> T, id: AnyHashable? = nil) -> Factory {
        main.register(factory(), id: id)
    }

    // MARK: Resolving

    /// Returns an instance of a service, returning nil if the service isn't
    /// registered to this container.
    ///
    /// - Parameters:
    ///   - type: The service type to resolve.
    ///   - id: An optional identifier to resolve with.
    public func resolve<T>(_ type: T.Type = T.self, id: AnyHashable? = nil) -> T? {
        lock.withLock {
            guard let factory = factories[Key(type: type, id: id)] else {
                return parent?.resolve(type, id: id)
            }

            guard let value = factory.value(in: self) as? T else {
                preconditionFailure("Internal storage type mismatch.")
            }

            return value
        }
    }

    /// Returns an instance of a service, throwing a `ContainerError` if the
    /// service isn't registered to this container.
    ///
    /// - Parameters:
    ///   - type: The service type to resolve.
    ///   - id: An optional identifier to resolve with.
    public func resolveOrThrow<T>(_ type: T.Type = T.self, id: AnyHashable? = nil) throws -> T {
        guard let unwrapped = resolve(type, id: id) else {
            let identifier = id.map { " with identifier \($0)" } ?? ""
            throw ContainerError("A \(T.self)\(identifier) wasn't registered to this container.")
        }

        return unwrapped
    }

    /// Returns an instance of a service, failing an assertion if the service
    /// isn't registered to this container.
    ///
    /// - Parameters:
    ///   - type: The service type to resolve.
    ///   - id: An optional identifier to resolve with.
    public func require<T>(_ type: T.Type = T.self, id: AnyHashable? = nil) -> T {
        guard let value = resolve(type, id: id) else {
            let identifier = id.map { " with identifier \($0)" } ?? ""
            preconditionFailure("Unable to resolve service of type \(T.self)\(identifier). Perhaps it isn't registered?")
        }

        return value
    }

    /// Returns an instance of a service from the main container, returning nil
    /// if the service isn't registered.
    ///
    /// - Parameters:
    ///   - type: The service type to resolve.
    ///   - id: An optional identifier to resolve with.
    public static func resolve<T>(_ type: T.Type = T.self, id: AnyHashable? = nil) -> T? {
        main.resolve(type, id: id)
    }

    /// Returns an instance of a service from the main container, throwing a
    /// `ContainerError` if the service isn't registered.
    ///
    /// - Parameters:
    ///   - type: The service type to resolve.
    ///   - id: An optional identifier to resolve with.
    public static func resolveOrThrow<T>(_ type: T.Type = T.self, id: AnyHashable? = nil) throws -> T {
        try main.resolveOrThrow(type, id: id)
    }

    /// Returns an instance of a service from the main container, failing an
    /// assertion if the service isn't registered to this container.
    ///
    /// - Parameters:
    ///   - type: The service type to resolve.
    ///   - id: An optional identifier to resolve with.
    public static func require<T>(_ type: T.Type = T.self, id: AnyHashable? = nil) -> T {
        main.require(type, id: id)
    }

    // MARK: KeyPath APIs

    @discardableResult
    public func set<Base, T>(_ key: KeyPath<Base, T>, value: T) -> Factory {
        register(value, id: key)
    }

    public func exists<Base, T>(_ key: KeyPath<Base, T>) -> Bool {
        resolve(T.self, id: key) != nil
    }

    public func get<Base, T>(_ key: KeyPath<Base, T>) -> T? {
        resolve(T.self, id: key)
    }

    public func require<Base, T>(_ key: KeyPath<Base, T>, error: StaticString? = nil) -> T {
        require(T.self, id: key)
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        guard !factories.isEmpty else {
            return """
                * Container *
                <nothing registered>
                """
        }

        let factoriesDescription = factories
            .map { key, factory in
                let idString = key.id.map { " (\($0.base))" } ?? ""
                let keyString = key.typeString + idString
                return "- \(keyString): \(factory.value(in: self)) (\(factory.scope))"
            }
            .sorted()
            .joined(separator: "\n")

        return """
            * Container *
            \(factoriesDescription)
            """
    }
}

#if os(Linux)
extension NSRecursiveLock {
    fileprivate func withLock<R>(_ body: () throws -> R) rethrows -> R {
        self.lock()
        let value: R
        do {
            value = try body()
        } catch {
            self.unlock()
            throw error
        }
        self.unlock()
        return value
    }
}
#endif
