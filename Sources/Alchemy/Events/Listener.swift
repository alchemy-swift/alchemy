/// Processes a specific type of `Event`.
public protocol Listener {
    associatedtype ObservedEvent: Event
    
    /// Create an intance of this listener for the given event.
    init(event: ObservedEvent)

    /// Handle the event this listener was created for.
    func run() async throws
}
