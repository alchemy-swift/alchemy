///// Used to identify different instances of common services in Alchemy.
//public struct ServiceIdentifier<Service>: Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
//    /// The default identifier for a service.
//    public static var `default`: Self { ServiceIdentifier(nil) }
//
//    private var identifier: AnyHashable?
//
//    public init(_ identifier: AnyHashable?) {
//        self.identifier = identifier
//    }
//
//    // MARK: - ExpressibleByStringLiteral
//
//    public init(stringLiteral value: String) {
//        self.init(value)
//    }
//
//    // MARK: - ExpressibleByIntegerLiteral
//
//    public init(integerLiteral value: Int) {
//        self.init(value)
//    }
//}
