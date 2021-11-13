import Lifecycle

public protocol Service {
    /// Start this service. Will be called when this service is first resolved.
    func startup()
    
    /// Shutdown this service. Will be called when the application your
    /// service is registered to shuts down.
    func shutdown() throws
}

extension Inject where Service: Alchemy.Service {
    convenience init(_ identifier: ServiceIdentifier<Service>) {
        self.init(identifier as AnyHashable)
    }
}

extension Service {
    /// An identifier, unique to your service.
    public typealias Identifier = ServiceIdentifier<Self>
    
    /// By default, startup and shutdown are no-ops.
    public func startup() {}
    public func shutdown() throws {}
}

// 1. Generic service with identifier (Router, Scheduler, ThreadPool)
// 2. Generic service with identifier & config (Database, Redis, Queue)

extension Service {
    public static var `default`: Self { resolve(.default) }
    
    public static func register(_ singleton: Self) {
        register(.default, singleton)
    }
    
    public static func register(_ identifier: Identifier = .default, _ singleton: Self) {
        // Register as a singleton to the default container.
        Container.default.register(singleton: Self.self, identifier: identifier) { _ in
            singleton.startup()
            return singleton
        }
        
        // Hook start / shutdown into the service lifecycle, if registered.
        Container.default
            .resolveOptional(ServiceLifecycle.self)?
            .registerShutdown(
                label: "\(name(of: Self.self)):\(identifier)",
                .sync(singleton.shutdown))
    }
    
    public static func resolve(_ identifier: Identifier = .default) -> Self {
        Container.resolve(Self.self, identifier: identifier)
    }
}
