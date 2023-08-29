/// An identified service provider.
public protocol Service {
    /// An identifier, unique to the service.
    associatedtype Identifier: Hashable
}

/// A type to be used as the identifier for various services.
public struct ServiceIdentifier<T>: Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    public let value: AnyHashable

    public init(value: AnyHashable) {
        self.value = value
    }

    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self.init(value: value)
    }

    // MARK: - ExpressibleByIntegerLiteral

    public init(integerLiteral value: Int) {
        self.init(value: value)
    }
}

extension Inject where Value: Service {
    public convenience init(_ identifier: Value.Identifier) {
        self.init(id: identifier)
    }
}
