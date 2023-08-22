public protocol Service {
    /// An identifier, unique to the service.
    associatedtype Identifier: ServiceIdentifier
}

public protocol ServiceIdentifier: Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    static var `default`: Self { get }
    init(hashable: AnyHashable)
}

extension ServiceIdentifier {
    public static var `default`: Self { Self(hashable: AnyHashable(nil as AnyHashable?)) }

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
