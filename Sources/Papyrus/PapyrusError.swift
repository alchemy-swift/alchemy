/// A Papyrus related error.
public struct PapyrusError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: what went wrong.
    public init(_ message: String) {
        self.message = message
    }
}
