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
        Container.default.register(singleton: ServiceLifecycle(
            configuration: ServiceLifecycle.Configuration(
                logger: lifecycleLogger,
                installBacktrace: !testing)))
        
        // Register all services
        
        if testing {
            Loop.mock()
        } else {
            Loop.config()
        }
        
        ServerConfiguration().registerDefault()
        Router().registerDefault()
        Scheduler().registerDefault()
        NIOThreadPool(numberOfThreads: System.coreCount).registerDefault()
        Client().registerDefault()
        
        if testing {
            FileCreator.mock()
        }
        
        // Set up any configurable services.
        let types: [Any.Type] = [Database.self, Cache.self, Queue.self]
        for type in types {
            if let type = type as? AnyConfigurable.Type {
                type.configureDefaults()
            }
        }
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

extension Service {
    fileprivate func registerDefault() {
        Self.register(self)
    }
}
