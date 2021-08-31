import Lifecycle
import NIO

/// Convenience class for easy access to the running `Application`'s
/// `EventLoopGroup` and currrent `EventLoop`.
public struct Loop {
    /// The event loop your code is currently running on.
    @Inject public static var current: EventLoop
    
    /// The main `EventLoopGroup` of the Application.
    @Inject public static var group: EventLoopGroup
    
    @Inject private static var lifecycle: ServiceLifecycle
    
    /// Configure the Applications `EventLoopGroup` and `EventLoop`.
    static func config() {
        Container.register(EventLoop.self) { _ in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
                fatalError("This code isn't running on an `EventLoop`!")
            }

            return current
        }
        
        Container.register(singleton: EventLoopGroup.self) { _ in
            MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        }
        
        lifecycle.registerShutdown(label: name(of: EventLoopGroup.self), .sync(group.syncShutdownGracefully))
    }
}
