/// A service that's configurable with a custom configuration
public protocol Configurable: AnyConfigurable {
    associatedtype Config
    
    static var config: Config { get }
    static func configure(using config: Config)
}

public protocol AnyConfigurable {
    static func configureDefaults()
}

extension Configurable {
    public static func configureDefaults() {
        configure(using: Self.config)
    }
}
