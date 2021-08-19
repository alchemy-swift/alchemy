import Fusion
import Lifecycle

public protocol Service {
    // Shutdown this service. Will be called when the main
    // application shuts down.
    func shutdown() throws
    
    static var `default`: Self { get }
    static func named(_ name: String) -> Self
    
    static func config(default: Self)
    static func config(_ name: String, _ driver: Self)
}

public extension Service {
    private static var lifecycle: ServiceLifecycle {
        Container.resolve(ServiceLifecycle.self)
    }
    
    func shutdown() throws {}
    
    static var `default`: Self {
        Container.resolve(Self.self)
    }
    
    static func named(_ name: String) -> Self {
        Container.resolve(Self.self, identifier: name)
    }
    
    static func config(default configuration: Self) {
        config(default: configuration, shutdownWithApp: true)
    }
    
    static func config(_ name: String, _ configuration: Self) {
        config(name, configuration, shutdownWithApp: true)
    }
    
    internal static func config(default configuration: Self, shutdownWithApp: Bool) {
        config(nil, configuration, shutdownWithApp: shutdownWithApp)
    }
    
    internal static func config(_ name: String? = nil, _ configuration: Self, shutdownWithApp: Bool) {
        let label: String
        if let name = name {
            label = "\(Alchemy.name(of: Self.self)):\(name)"
            Container.register(singleton: Self.self, identifier: name) { _ in configuration }
        } else {
            label = "\(Alchemy.name(of: Self.self))"
            Container.register(singleton: Self.self) { _ in configuration }
        }
        
        if shutdownWithApp {
            lifecycle.registerShutdown(label: label, .sync(configuration.shutdown))
        }
    }
}
