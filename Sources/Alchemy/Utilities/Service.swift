import Fusion
import Lifecycle

public protocol Service {
    // Shutdown this service. Will be called when the main application
    // shuts down.
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
    public func shutdown() throws {}
    
    public static var `default`: Self {
        Container.resolve(Self.self)
    }
    
    public static func named(_ name: String) -> Self {
        Container.resolve(Self.self, identifier: name)
    }
    
    public static func config(default configuration: Self) {
        config(default: configuration)
    }
    
    public static func config(_ name: String, _ configuration: Self) {
        config(name, configuration)
    }
    
    private static func config(_ name: String? = nil, _ configuration: Self) {
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
    }
}
