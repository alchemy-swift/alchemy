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
                    logger: lifecycleLogger)))
        
        Loop.config()
        
        // Register all services
        ApplicationConfiguration.config(default: ApplicationConfiguration())
        Router.config(default: Router())
        Scheduler.config(default: Scheduler())
        NIOThreadPool.config(default: NIOThreadPool(numberOfThreads: System.coreCount))
        Client.config(default: Client())
        
        // Start threadpool
        NIOThreadPool.default.start()
    }
    
    /// Mocks many common services. Can be called in the `setUp()`
    /// function of test cases.
    public func mockServices() {
        Container.default = Container()
        
        var lifecycleLogger = Log.logger
        lifecycleLogger.logLevel = lifecycleLogLevel
        ServiceLifecycle.config(
            default: ServiceLifecycle(
                configuration: ServiceLifecycle.Configuration(
                    logger: lifecycleLogger,
                    installBacktrace: false)))
        
        Loop.mock()
        Router.config(default: Router())
        Client.config(default: Client())
        Scheduler.config(default: Scheduler())
        NIOThreadPool.config(default: NIOThreadPool(numberOfThreads: System.coreCount))
    }
}

extension NIOThreadPool: Service {
    public func shutdown() throws {
        try syncShutdownGracefully()
    }
}

extension ServiceLifecycle: Service {}
