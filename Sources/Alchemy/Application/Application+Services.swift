import Fusion
import Lifecycle

extension Application {
    /// Register core services to `Container.default`.
    func bootServices() {
        // Setup app lifecycle
        var lifecycleLogger = Log.logger
        lifecycleLogger.logLevel = lifecycleLogLevel
        ServiceLifecycle.config(
            default: ServiceLifecycle(
                configuration: ServiceLifecycle.Configuration(
                    logger: lifecycleLogger,
                    installBacktrace: true
                )))
        
        Loop.config()
        
        // Register all services
        ApplicationConfiguration.config(default: ApplicationConfiguration())
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
        ServiceLifecycle.config(default: ServiceLifecycle())
        Router.config(default: Router())
        Loop.mock()
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
