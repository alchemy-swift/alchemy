import Fusion
import Lifecycle

extension Application {
    /// Register core services to `Container.default`.
    ///
    /// - Parameter testing: If `true`, default services will be configured in a
    ///   manner appropriate for tests.
    func bootServices(testing: Bool = false) {
        if testing {
            Container.default = Container()
        }
        
        // Setup app lifecycle
        var lifecycleLogger = Log.logger
        lifecycleLogger.logLevel = lifecycleLogLevel

        // Register all services
        ServiceLifecycle(
            configuration: ServiceLifecycle.Configuration(
                logger: lifecycleLogger,
                installBacktrace: !testing)).makeDefault()
        if testing {
            Loop.mock()
        } else {
            Loop.config()
        }
        
        ServerConfiguration().makeDefault()
        Router().makeDefault()
        Scheduler().makeDefault()
        NIOThreadPool(numberOfThreads: System.coreCount).makeDefault()
        Client().makeDefault()
    }
}

extension NIOThreadPool: Service {
    public func startup() {
        start()
    }
    
    public func shutdown() throws {
        try syncShutdownGracefully()
    }
}

extension ServiceLifecycle: Service {}

extension Service {
    func makeDefault() {
        Self.config(default: self)
    }
}
