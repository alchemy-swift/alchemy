// There is one and only one of a `SingletonService` to be injected.
public protocol SingletonService: Fusable {
    static func singleton(in container: Container) throws -> Self
}

public extension Inject where Value: SingletonService {
    convenience init() {
        self.init { try $0.resolve() }
    }
}
