// There are multiple singletons of `IdentifiedService`, but each is unique to an identifier.
public protocol IdentifiedService: Fusable {
    associatedtype Identifier: Hashable
    static func singleton(in container: Container, for identifier: Identifier) throws -> Self
}

public extension Inject where Value: IdentifiedService {
    convenience init() {
        fatalError("`IdentifiedService`s should be initialized using `init(_ identifier)` below.")
    }
    
    convenience init(_ identifier: Value.Identifier) {
        self.init { try $0.resolve(identifier: identifier) }
    }
}

extension IdentifiedService {
    /// Gets a service instance from the global `Container`, or crashes if one isn't registered.
    public static func global(_ id: Identifier) -> Self { try! Container.global.resolve(identifier: id) }
}
