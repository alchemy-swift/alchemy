import NIO

/// Can't call static properties from a protocol so this is used for getting the current event loop.
public struct Loop {
    public static var current: EventLoop {
        guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
            fatalError("Unable to find an event loop associated with this thread. Try passing it in manually.")
        }

        return current
    }
    
    public static func future<T>(error: Error) -> EventLoopFuture<T> {
        Loop.current.makeFailedFuture(error)
    }
    
    public static func future<T>(value: T) -> EventLoopFuture<T> {
        Loop.current.makeSucceededFuture(value)
    }
}
