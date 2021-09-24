import ArgumentParser

public protocol Command: ParsableCommand {
    static var shutdownAfterRun: Bool { get }
    static var logStartAndFinish: Bool { get }

    func start() -> EventLoopFuture<Void>
    func shutdown() -> EventLoopFuture<Void>
}

extension Command {
    public static var shutdownAfterRun: Bool { true }
    public static var logStartAndFinish: Bool { true }

    public func run() throws {
        if Self.logStartAndFinish {
            Log.info("[Command] running \(commandName)")
        }
        // By default, register self to lifecycle
        registerToLifecycle()
    }
    
    public func shutdown() -> EventLoopFuture<Void> {
        if Self.logStartAndFinish {
            Log.info("[Command] finished \(commandName)")
        }
        return .new()
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
    
    private var commandName: String {
        name(of: Self.self)
    }
}
