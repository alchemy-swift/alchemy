public protocol Timestamps {
    static var createdAtKey: String { get }
    static var updatedAtKey: String { get }
}

extension Timestamps {
    public static var createdAtKey: String { "createdAt" }
    public static var updatedAtKey: String { "updatedAt" }
}
