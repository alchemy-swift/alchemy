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
/// struct SyncUserData: Command {
///     static var configuration = CommandConfiguration(commandName: "sync", discussion: "Sync all data for all users.")
///
///     @Option(help: "Sync data for a specific user only.")
///     var id: Int?
///
///     @Flag(help: "Should data be loaded but not saved.")
///     var dry: Bool = false
///
///     func run() async throws {
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
/// $ swift run app sync --id 2 --dry
/// ```
public protocol Command: AsyncParsableCommand {
    /// The name of this command. Run it in the command line by passing this
    /// name as an argument. Defaults to the type name.
    static var name: String { get }

    /// When running the app with this command, should the app
    /// stay alive after `run` is finished.
    static var runUntilStopped: Bool { get }

    /// Run the command.
    func run() async throws
}

extension Command {
    public static var runUntilStopped: Bool { false }

    public static var name: String {
        Alchemy.name(of: Self.self)
    }
    
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: name)
    }
}
