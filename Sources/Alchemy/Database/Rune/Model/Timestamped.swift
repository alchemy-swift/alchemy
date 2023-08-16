public protocol Timestamped {
    static var createdAtKey: String { get }
    static var updatedAtKey: String { get }
}

extension Timestamped {
    public static var createdAtKey: String { "createdAt" }
    public static var updatedAtKey: String { "updatedAt" }
}

extension Timestamped where Self: Model {
    public var createdAt: Date? {
        try? row?[Self.createdAtKey]?.date()
    }

    public var updatedAt: Date? {
        try? row?[Self.updatedAtKey]?.date()
    }
}
