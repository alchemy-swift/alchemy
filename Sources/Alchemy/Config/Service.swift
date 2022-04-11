import Lifecycle

public protocol Service {
    /// An identifier, unique to the service.
    associatedtype Identifier: ServiceIdentifier
    /// Start this service. Will be called when this service is first resolved.
    func startup()
    /// Shutdown this service. Will be called when the application your
    /// service is registered to shuts down.
    func shutdown() throws
}

public protocol ServiceIdentifier: Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    static var `default`: Self { get }
    init(hashable: AnyHashable)
}

extension ServiceIdentifier {
    public static var `default`: Self { Self(hashable: AnyHashable(nil as AnyHashable?)) }
    
    // MARK: - ExpressibleByStringLiteral
    
    public init(stringLiteral value: String) {
        self.init(hashable: value)
    }
    
    // MARK: - ExpressibleByIntegerLiteral
    
    public init(integerLiteral value: Int) {
        self.init(hashable: value)
    }
}

// By default, startup and shutdown are no-ops.
extension Service {
    public func startup() {}
    public func shutdown() throws {}
}

extension Service {
    
    // MARK: Resolve shorthand
    
    public static var `default`: Self {
        .id(.default)
    }
    
    public static func id(_ identifier: Identifier) -> Self {
        Container.resolveAssert(Self.self, identifier: identifier)
    }
    
    // MARK: Bind shorthand
    
    public static func bind(_ value: @escaping @autoclosure () -> Self) {
        bind(.default, value())
    }
    
    public static func bind(_ identifier: Identifier = .default, _ value: Self) {
        // Register as a singleton to the default container.
        Container.bind(.singleton, identifier: identifier) { container -> Self in
            value.startup()
            return value
        }
        
        // Need to register shutdown before lifecycle starts, but need to shutdown EACH singleton,
        Container.resolveAssert(ServiceLifecycle.self)
            .registerShutdown(label: "\(name(of: Self.self)):\(identifier)", .sync {
                try value.shutdown()
            })
    }
}

extension Inject where Service: Alchemy.Service {
    public convenience init(_ identifier: Service.Identifier) {
        self.init(identifier: identifier)
    }
}
