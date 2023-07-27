/// An error encountered when interacting with a `Database`.
public struct DatabaseError: Error {
    /// What went wrong.
    public let message: String
    
    /// Initialize a `DatabaseError` with a message detailing what
    /// went wrong.
    ///
    /// - Parameter message: Why this error was thrown.
    init(_ message: String) {
        self.message = message
    }
}
