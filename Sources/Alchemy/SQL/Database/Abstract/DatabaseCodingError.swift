/// An error encountered when decoding a `DatabaseCodable` from a `DatabaseRow` or encoding it to
/// a `[DatabaseField]`.
struct DatabaseCodingError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize a `DatabaseCodingError` with a message detailing what went wrong.
    ///
    /// - Parameter message: why this error was thrown.
    init(_ message: String) {
        self.message = message
    }
}
