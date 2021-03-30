/// An error encountered when interacting with a `Job`.
public struct JobError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize with a message.
    ///
    /// - Parameter message: Why this error was thrown.
    init(_ message: String) {
        self.message = message
    }
}
