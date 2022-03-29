/// Processes an Event
public protocol Listener {
    associatedtype ObservedEvent: Event
    init(event: ObservedEvent)
    func run() async throws
}
