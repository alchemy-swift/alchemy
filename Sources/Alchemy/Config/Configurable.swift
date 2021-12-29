/// A service that's configurable with a custom configuration
public protocol Configurable: AnyConfigurable {
    associatedtype Config
    
    static var config: Config { get }
    static func configure(using config: Config)
}

/// Register services that the user may provide configurations for here.
/// Services registered here will have their default configurations run
/// before the main application boots.
public struct ConfigurableServices {
    private static var configurableTypes: [Any.Type] = [
        Database.self,
        Cache.self,
        Queue.self,
        Filesystem.self
    ]
    
    public static func register<T>(_ type: T.Type) {
        configurableTypes.append(type)
    }
    
    static func configureDefaults() {
        for type in configurableTypes {
            if let type = type as? AnyConfigurable.Type {
                type.configureDefaults()
            }
        }
    }
}

/// An erased configurable.
public protocol AnyConfigurable {
    static func configureDefaults()
}

extension Configurable {
    public static func configureDefaults() {
        configure(using: Self.config)
    }
}
