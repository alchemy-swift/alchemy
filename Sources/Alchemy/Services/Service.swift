/// An identified service provider.
public protocol Service {
    /// An identifier, unique to the service.
    associatedtype Identifier: Hashable
}

/// A type to be used as the identifier for various services.
public struct ServiceIdentifier<T>: Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    private let value: AnyHashable

    public init(value: AnyHashable) {
        self.value = value
    }

    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self.value = value
    }

    // MARK: - ExpressibleByIntegerLiteral

    public init(integerLiteral value: Int) {
        self.value = value
    }
}

extension Inject where Value: Service {
    public convenience init(_ identifier: Value.Identifier) {
        self.init(id: identifier)
    }
}
