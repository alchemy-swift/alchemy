/// An error encountered when interacting with a `Database`.
struct DatabaseError: Error {
    /// What went wrong.
    let message: String
    
    /// Initialize a `DatabaseError` with a message detailing what went wrong.
    ///
    /// - Parameter message: why this error was thrown.
    init(_ message: String) { self.message = message }
}
