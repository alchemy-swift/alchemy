/// Any general error that might occur when using the Rune ORM.
public struct RuneError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create a `RuneError` with the given message.
    ///
    /// - Parameter message: a message detailing the error.
    private init(_ message: String) { self.message = message }
    
    // MARK: All `RuneError`s.
    
    public static let notFound = RuneError("Unable to find an element of this type.")
    public static let relationshipWasNil = RuneError("Error unwrapping this `Relationship`.")
    public static let syncErrorNoId = RuneError("Can't .sync() an object with a nil `id`.")
    public static func syncErrorNoMatch<P: PrimaryKey>(table: String, id: P) -> RuneError {
        RuneError("Error syncing Model, didn't find a row with id '\(id)' on table '\(table)'.")
    }
}
