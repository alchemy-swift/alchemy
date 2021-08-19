import Lifecycle
import NIO

public struct Loop {
    @Inject public static var current: EventLoop
    @Inject public static var group: EventLoopGroup
    @Inject private static var lifecycle: ServiceLifecycle
    
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
