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
            Container.main = Container()
            Log.logger.logLevel = .notice
        }
        
        Env.boot()
        Container.bind(value: Env.current)
        
        // Register as Self & Application
        Container.bind(.singleton, to: Application.self, value: self)
        Container.bind(.singleton, value: self)
        
        // Setup app lifecycle
        Container.bind(.singleton, value: ServiceLifecycle(
            configuration: ServiceLifecycle.Configuration(
                logger: Log.logger.withLevel(.notice),
                installBacktrace: !testing)))
        
        // Register all services
        
        if testing {
            Loop.mock()
        } else {
            Loop.config()
        }
        
        Container.bind(.singleton, value: Router())
        Container.bind(.singleton, value: Scheduler())
        Container.bind(.singleton) { container -> NIOThreadPool in
            let threadPool = NIOThreadPool(numberOfThreads: System.coreCount)
            threadPool.start()
            container
                .resolve(ServiceLifecycle.self)?
                .registerShutdown(label: "\(name(of: NIOThreadPool.self))", .sync(threadPool.syncShutdownGracefully))
            return threadPool
        }
        
        Client.bind(Client())
        
        if testing {
            FileCreator.mock()
        }

        // Set up any configurable services.
        ConfigurableServices.configureDefaults()
    }
}

extension Logger {
    fileprivate func withLevel(_ level: Logger.Level) -> Logger {
        var copy = self
        copy.logLevel = level
        return copy
    }
}
