public protocol Service {
    /// An identifier, unique to the service.
    associatedtype Identifier: ServiceIdentifier
}

public protocol ServiceIdentifier: Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    init(hashable: AnyHashable)
}

extension ServiceIdentifier {

    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self.init(hashable: value)
    }

    // MARK: - ExpressibleByIntegerLiteral

    public init(integerLiteral value: Int) {
        self.init(hashable: value)
    }
}

extension Inject where Service: Alchemy.Service {
    public convenience init(_ identifier: Service.Identifier) {
        self.init(id: identifier)
    }
}
