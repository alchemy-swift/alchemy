/// Used to identify different instances of common services in Alchemy.
public struct ServiceIdentifier<Service>: Hashable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByNilLiteral {
    /// The default identifier for a service.
    public static var `default`: Self { nil }
    
    private var identifier: AnyHashable?
    
    private init(identifier: AnyHashable?) {
        self.identifier = identifier
    }
    
    public init(_ string: String) {
        self.init(identifier: string)
    }
    
    public init(_ int: Int) {
        self.init(identifier: int)
    }
    
    // MARK: - ExpressibleByStringLiteral
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
    
    // MARK: - ExpressibleByIntegerLiteral
    
    public init(integerLiteral value: Int) {
        self.init(value)
    }
    
    // MARK: - ExpressibleByNilLiteral
    
    public init(nilLiteral: Void) {
        self.init(identifier: nil)
    }
}
