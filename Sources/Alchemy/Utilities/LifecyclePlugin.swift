struct LifecyclePlugin: Plugin {
    func registerServices(in container: Container) {
        container.registerSingleton(
            ServiceLifecycle(
                configuration: ServiceLifecycle.Configuration(
                    logger: Log.logger.withLevel(.notice),
                    installBacktrace: !container.env.isTesting
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

extension Logger {
    fileprivate func withLevel(_ level: Logger.Level) -> Logger {
        var copy = self
        copy.logLevel = level
        return copy
    }
}
