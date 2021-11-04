import Fusion
import Lifecycle

/// A protocol for registering and resolving a type through Alchemy's
/// dependency injection system, Fusion. Conform a type to this
/// to make it simple to inject and resolve around your app.
public protocol Service {
    // Start this service. Will be called immediately after your service is
    // registered.
    func startup()
    
    // Shutdown this service. Will be called when the application your
    // service is registered to shuts down.
    func shutdown() throws
    
    /// The default instance of this service.
    static var `default`: Self { get }

    /// A named instance of this service.
    ///
    /// - Parameter name: The name of the service to fetch.
    static func named(_ name: String) -> Self
    
    /// Register the default driver for this service.
    static func config(default: Self)
    
    /// Register a named driver driver for this service.
    static func config(_ name: String, _ driver: Self)
}

// Default implementations.
extension Service {
    public func startup() {}
    public func shutdown() throws {}
    
    public static var `default`: Self {
        Container.resolve(Self.self)
    }
    
    public static func named(_ name: String) -> Self {
        Container.resolve(Self.self, identifier: name)
    }
    
    public static func config(default configuration: Self) {
        _config(nil, configuration)
    }
    
    public static func config(_ name: String, _ configuration: Self) {
        _config(name, configuration)
    }
    
    private static func _config(_ name: String? = nil, _ configuration: Self) {
        let label: String
        if let name = name {
            label = "\(Alchemy.name(of: Self.self)):\(name)"
            Container.register(singleton: Self.self, identifier: name) { _ in configuration }
        } else {
            label = "\(Alchemy.name(of: Self.self))"
            Container.register(singleton: Self.self) { _ in configuration }
        }
        
        if
            !(configuration is ServiceLifecycle),
            let lifecycle = Container.resolveOptional(ServiceLifecycle.self)
        {
            lifecycle.registerShutdown(label: label, .sync(configuration.shutdown))
        }
        
        configuration.startup()
    }
}
