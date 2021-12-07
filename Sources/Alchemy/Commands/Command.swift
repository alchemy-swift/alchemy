import ArgumentParser

/// An interface for defining custom commands. Implement `start()`,
/// register your command type to your application, and you're
/// off to the races.
///
/// Note that this is built on top of `Swift Argument Parser` and so
/// your command will have access to all of those APIs.
///
/// First, conform to the `Command` interface.
///
/// ```swift
/// final class SyncUserData: Command {
///     static var configuration = CommandConfiguration(commandName: "sync", discussion: "Sync all data for all users.")
///
///     @Option(help: "Sync data for a specific user only.")
///     var id: Int?
///
///     @Flag(help: "Should data be loaded but not saved.")
///     var dry: Bool = false
///
///     func start() async throws {
///         if let userId = id {
///             // sync only a specific user's data
///         } else {
///             // sync all users' data
///         }
///     }
/// }
/// ```
///
/// Next, register your command type.
///
/// ```swift
/// app.registerCommand(SyncUserData.self)
/// ```
///
/// Now you may run your Alchemy app with your new command.
///
/// ```bash
/// $ swift run MyApp sync --id 2 --dry
/// ```
public protocol Command: ParsableCommand {
    /// The name of this command. Run it in the command line by passing this
    /// name as an argument. Defaults to the type name.
    static var name: String { get }
    
    /// When running the app with this command, should the app
    /// shut down after the command `start()` is finished.
    /// Defaults to `true`.
    ///
    /// In most cases this is yes, unless the command performs
    /// indefinitely running work such as starting a queue
    /// worker or running the server.
    static var shutdownAfterRun: Bool { get }
    
    /// Should the start and finish of this command be logged. Defaults to true.
    static var logStartAndFinish: Bool { get }
    
    /// Run the command. Your command's main logic should be here.
    func start() async throws
    
    /// An optional function to run when your command receives a
    /// shutdown signal. You likely don't need this unless your
    /// command runs indefinitely. Defaults to a no-op.
    func shutdown() async throws
}

extension Command {
    public static var shutdownAfterRun: Bool { true }
    public static var logStartAndFinish: Bool { true }
    
    /// Registers this command with the application lifecycle.
    public func run() throws {
        registerWithLifecycle()
    }
    
    public func shutdown() {}

    /// Registers this command to the application lifecycle; useful
    /// for running the app with this command.
    func registerWithLifecycle() {
        @Inject var lifecycle: ServiceLifecycle
        
        lifecycle.register(
            label: Self.configuration.commandName ?? Alchemy.name(of: Self.self),
            start: .eventLoopFuture {
                Loop.group.next()
                    .asyncSubmit {
                        if Self.logStartAndFinish {
                            Log.info("[Command] running \(Self.name)")
                        }
                        
                        try await start()
                    }
                    .map {
                        if Self.shutdownAfterRun {
                            lifecycle.shutdown()
                        }
                    }
            },
            shutdown: .eventLoopFuture {
                Loop.group.next()
                    .asyncSubmit {
                        if Self.logStartAndFinish {
                            Log.info("[Command] finished \(Self.name)")
                        }
                        
                        try await shutdown()
                    }
            }
        )
    }
    
    public static var name: String {
        Alchemy.name(of: Self.self)
    }
    
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: name)
    }
}
