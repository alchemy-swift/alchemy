/// An error encountered when running a Command.
public struct CommandError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize a `CommandError` with a message detailing what
    /// went wrong.
    init(_ message: String) {
        self.message = message
    }
}
