import NIO

/// This struct exists soley to give an easy way to access the current `EventLoop`. Accessing
/// `current` will return the current event loop or fatal if this is called outside of an
/// `EventLoop`.
public struct Loop {
    /// The current event loop of execution. Accessing this will `fatalError` if the current
    /// execution is not on an EventLoop.
    public static var current: EventLoop {
        guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
            fatalError("Unable to find an event loop associated with this thread. Try passing it in"
                        + " manually.")
        }

        return current
    }
}
