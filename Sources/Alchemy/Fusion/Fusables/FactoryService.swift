// A new instances of a `FactoryService` is created each time it is injected.
public protocol FactoryService: Fusable {
    static var factory: (Container) throws -> Self { get }
}

public extension Inject where Value: FactoryService {
    convenience init() {
        self.init { try $0.resolve() }
    }
}
