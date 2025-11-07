
/// Accessor for firing events; applications should listen to events via
/// `Application.schedule(events: EventBus)`.
public var Events: EventBus {
    Container.events
}

extension Container {
    @Service(.singleton) var events = EventBus()
}
