import Fusion
import Lifecycle

extension Application {
    /// Register some commonly used services to `Container.default`.
    func bootServices() {
        Loop.config()
        
        // Register all services
        Router.config(default: Router())
        Scheduler.config(default: Scheduler())
        NIOThreadPool.config(default: NIOThreadPool(numberOfThreads: System.coreCount))
        HTTPClient.config(default: HTTPClient(eventLoopGroupProvider: .shared(Loop.group)))
        
        // Start threadpool
        NIOThreadPool.default.start()
    }
    
    /// Mocks many common services. Can be called in the `setUp()`
    /// function of test cases.
    public func mockServices() {
        Container.default = Container()
        Container.register(singleton: ServiceLifecycle.self) { _ in ServiceLifecycle() }
        Container.register(singleton: Router.self) { _ in Router() }
        Container.register(EventLoop.self) { _ in EmbeddedEventLoop() }
        Container.register(singleton: EventLoopGroup.self) { _ in MultiThreadedEventLoopGroup(numberOfThreads: 1) }
    }
}

extension HTTPClient: Service {
    public func shutdown() throws {
        try syncShutdown()
    }
}

extension NIOThreadPool: Service {
    public func shutdown() throws {
        try syncShutdownGracefully()
    }
}

extension ServiceLifecycle: Service {}
