/// Processes a specific type of `Event`.
public protocol Listener {
    associatedtype ObservedEvent: Event
    
    /// Handle the event this listener was created for.
    func handle(event: ObservedEvent) async throws
}
