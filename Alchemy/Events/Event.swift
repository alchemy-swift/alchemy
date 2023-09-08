/// An app-wide event to be fired by an `EventBus`.
public protocol Event {
    /// The key for which the event is registered in the `EventBus`. Defaults to
    /// the type name.
    static var registrationKey: String { get }
}

extension Event {
    public static var registrationKey: String { name(of: Self.self) }

    /// Fire this event on an `EventBus`.
    public func fire(on bus: EventBus = Events) async throws {
        try await bus.fire(self)
    }
}
