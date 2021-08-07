import Fusion

public protocol Service {
    static var `default`: Self { get }
    static func named(_ name: String) -> Self
    
    static func config(default: Self)
    static func config(_ name: String, _ driver: Self)
}

public extension Service {
    static var `default`: Self {
        Container.global.resolve(Self.self)
    }
    
    static func named(_ name: String) -> Self {
        Container.global.resolve(Self.self, identifier: name)
    }
    
    static func config(default configuration: Self) {
        Container.global.register(singleton: Self.self) { _ in configuration }
    }
    
    static func config(_ name: String, _ configuration: Self) {
        Container.global.register(singleton: Self.self, identifier: name) { _ in configuration }
    }
}
