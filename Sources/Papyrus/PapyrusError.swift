/// A Papyrus related error.
public struct PapyrusError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    public init(_ message: String) {
        self.message = message
    }
}

/// An error related to decoding a type from a `DecodableRequest`.
public struct PapyrusValidationError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    public init(_ message: String) {
        self.message = message
    }
}
