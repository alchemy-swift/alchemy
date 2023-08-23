/// An app-wide event fired by an `EventBus`.
public protocol Event {
    /// The key for which the event is registered in the `EventBus`. Defaults to
    /// the type name.
    static var registrationKey: String { get }
}

extension Event {
    public static var registrationKey: String { name(of: Self.self) }
}
