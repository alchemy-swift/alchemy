import ServiceLifecycle

final class Lifecycle: ServiceLifecycle.Service {
    fileprivate var startTasks: [() async throws -> Void] = []
    fileprivate var shutdownTasks: [() async throws -> Void] = []

    var didStart = false
    var didStop = false

    func run() async throws {
        try await start()
        try await gracefulShutdown()
        try await shutdown()
    }

    func start() async throws {
        guard !didStart else { return }
        didStart = true
        for start in startTasks {
            try await start()
        }
    }

    func shutdown() async throws {
        guard !didStop else { return }
        didStop = true
        for shutdown in shutdownTasks.reversed() {
            try await shutdown()
        }
    }
}

extension Application {
    var lifecycle: Lifecycle {
        container.require()
    }
}

extension Container {
    static var lifecycle: Lifecycle {
        require()
    }

    public static func onStart(action: @escaping () async throws -> Void) {
        lifecycle.startTasks.append(action)
    }

    public static func onShutdown(action: @escaping () async throws -> Void) {
        lifecycle.shutdownTasks.append(action)
    }
}
