/// An error encountered when interacting with a `Client`.
public struct ClientError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize a `ClientError` with a message detailing what
    /// went wrong.
    ///
    /// - Parameter message: Why this error was thrown.
    init(_ message: String) {
        self.message = message
    }
}
