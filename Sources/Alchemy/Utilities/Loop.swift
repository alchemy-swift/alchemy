import NIO

/// Can't call static properties from a protocol so this is used for getting the current event loop.
public struct Loop {
    public static var current: EventLoop {
        guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
            fatalError("Unable to find an event loop associated with this thread. Try passing it in manually.")
        }

        return current
    }
}
