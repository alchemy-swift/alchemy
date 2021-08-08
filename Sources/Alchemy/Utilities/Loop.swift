import NIO

public struct Loop {
    @Inject public static var current: EventLoop
    @Inject public static var group: EventLoopGroup
    
    static func setup() {
        Container.global.register(EventLoop.self) { _ in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
                fatalError("This code isn't running on an `EventLoop`!")
            }

            return current
        }
        
        Container.global.register(singleton: EventLoopGroup.self) { _ in
            MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        }
    }
}
