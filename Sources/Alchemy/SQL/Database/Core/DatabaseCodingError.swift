/// An error encountered when decoding or encoding a `Model`.
struct DatabaseCodingError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize a `DatabaseCodingError` with a message detailing
    /// what went wrong.
    ///
    /// - Parameter message: Why this error was thrown.
    init(_ message: String) {
        self.message = message
    }
}
