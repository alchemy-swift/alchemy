/// A listener that handles its events on a background `Queue`.
public protocol QueueableListener: Listener where ObservedEvent: Codable {
    /// The queue where events will be dispatched.
    var queue: Queue { get }

    /// The channel on which events will be dispatched.
    var channel: String { get }

    /// Whether the event should be dispatched on a Queue or handled
    /// immediately. Defaults to true.
    func shouldQueue(event: Event) -> Bool
}

extension QueueableListener {
    public var queue: Queue { Q }
    public var channel: String { Queue.defaultChannel }
    public func shouldQueue(event: Event) -> Bool { true }
}
