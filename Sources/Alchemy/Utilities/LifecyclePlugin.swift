struct LifecyclePlugin: Plugin {
    func registerServices(in container: Container) {
        container.registerSingleton(
            ServiceLifecycle(
                configuration: ServiceLifecycle.Configuration(
                    logger: {
                        var logger = Log.logger

                        // ServiceLifecycle is pretty noisy. Let's default it to
                        // logging @ .notice or above, unless the user has set
                        // the default log level to .debug or below.
                        if logger.logLevel > .debug {
                            logger.logLevel = .notice
                        }

                        return logger
                    }(),
                    installBacktrace: !container.env.isTest
                )
            )
        )
    }
}

extension Application {
    public var lifecycle: ServiceLifecycle {
        Container.resolveAssert()
    }
}
