import Lifecycle

extension Application {
    /// Register some commonly used services to `Container.global`.
    func bootServices(lifecycle: ServiceLifecycle) {
        Loop.setup()
        
        // Register all services
        ServiceLifecycle.config(default: lifecycle)
        Router.config(default: Router())
        Scheduler.config(default: Scheduler())
        NIOThreadPool.config(default: NIOThreadPool(numberOfThreads: System.coreCount))
        HTTPClient.config(default: HTTPClient(eventLoopGroupProvider: .shared(Loop.group)))
        
        // Start threadpool
        NIOThreadPool.default.start()
    }
    
    /// Shutdown some commonly used services registered to
    /// `Container.global`.
    ///
    /// This should not be run on an `EventLoop`!
    func shutdownServices() throws {
        try HTTPClient.default.syncShutdown()
        try Container.global.resolveOptional(Database.self)?.shutdown()
        try Container.global.resolveOptional(Redis.self)?.shutdown()
        try NIOThreadPool.default.syncShutdownGracefully()
        try Loop.group.syncShutdownGracefully()
    }
    
    /// Mocks many common services. Can be called in the `setUp()`
    /// function of test cases.
    public func mockServices() {
        Container.global = Container()
        Container.global.register(singleton: Router.self) { _ in Router() }
        Container.global.register(EventLoop.self) { _ in EmbeddedEventLoop() }
        Container.global.register(singleton: EventLoopGroup.self) { _ in MultiThreadedEventLoopGroup(numberOfThreads: 1) }
    }
}

extension HTTPClient: Service {}
extension NIOThreadPool: Service {}
extension ServiceLifecycle: Service {}
