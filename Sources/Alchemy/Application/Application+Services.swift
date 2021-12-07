import Fusion
import Lifecycle
import Logging

extension Application {
    /// Register core services to `Container.default`.
    ///
    /// - Parameter testing: If `true`, default services will be configured in a
    ///   manner appropriate for tests.
    func bootServices(testing: Bool = false) {
        if testing {
            Container.default = Container()
            Log.logger.logLevel = .notice
        }
        
        Env.boot()
        Container.register(singleton: self)
        
        // Setup app lifecycle
        Container.default.register(singleton: ServiceLifecycle(
            configuration: ServiceLifecycle.Configuration(
                logger: Log.logger.withLevel(.notice),
                installBacktrace: !testing)))
        
        // Register all services
        
        if testing {
            Loop.mock()
        } else {
            Loop.config()
        }
        
        Router().registerDefault()
        Scheduler().registerDefault()
        NIOThreadPool(numberOfThreads: System.coreCount).registerDefault()
        Client().registerDefault()
        
        if testing {
            FileCreator.mock()
        }
        
        // Set up any configurable services.
        let types: [Any.Type] = [
            Database.self,
            Store.self,
            Queue.self,
            Filesystem.self
        ]
        
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

extension Logger {
    fileprivate func withLevel(_ level: Logger.Level) -> Logger {
        var copy = self
        copy.logLevel = level
        return copy
    }
}
