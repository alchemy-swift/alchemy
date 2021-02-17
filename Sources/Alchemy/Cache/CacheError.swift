/// An error encountered when interacting with a `Cache`.
public struct CacheError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize a `CacheError` with a message detailing what
    /// went wrong.
    ///
    /// - Parameter message: Why this error was thrown.
    init(_ message: String) {
        self.message = message
    }
}
