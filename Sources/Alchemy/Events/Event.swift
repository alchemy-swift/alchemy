public protocol Event {
    static var registrationKey: String { get }
}

extension Event {
    public static var registrationKey: String { name(of: Self.self) }
}
