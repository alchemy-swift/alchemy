import ArgumentParser

public protocol Command: ParsableCommand {
    static var shutdownAfterRun: Bool { get }

    func start() -> EventLoopFuture<Void>
    func shutdown() -> EventLoopFuture<Void>
}

extension Command {
    public static var shutdownAfterRun: Bool { true }

    public func run() throws {
        // By default, register self to lifecycle
        registerToLifecycle()
    }

    public func registerToLifecycle() {
        let lifecycle = ServiceLifecycle.default
        lifecycle.register(
            label: Self.configuration.commandName ?? name(of: Self.self),
            start: .eventLoopFuture {
                Loop.group.next()
                    .flatSubmit(start)
                    .map {
                        if Self.shutdownAfterRun {
                            lifecycle.shutdown()
                        }
                    }
            },
            shutdown: .eventLoopFuture { Loop.group.next().flatSubmit(shutdown) }
        )
    }

    func shutdown() -> EventLoopFuture<Void> {
        .new()
    }
}
