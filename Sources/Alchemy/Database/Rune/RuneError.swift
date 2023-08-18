/// Any general error that might occur when using the Rune ORM.
public struct RuneError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create a `RuneError` with the given message.
    ///
    /// - Parameter message: A message detailing the error.
    public init(_ message: String) { self.message = message }
    
    // MARK: All `RuneError`s.
    
    /// A `Model` wasn't found.
    public static let notFound = RuneError("Unable to find an element of this type.")
}
