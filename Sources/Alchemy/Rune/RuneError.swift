/// Any general error that might occur when using the Rune ORM.
public struct RuneError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create a `RuneError` with the given message.
    ///
    /// - Parameter message: A message detailing the error.
    private init(_ message: String) { self.message = message }
    
    // MARK: All `RuneError`s.
    
    /// A `Model` wasn't found.
    public static let notFound = RuneError("Unable to find an element of this type.")
    
    /// Couldn't unwrap a relationship that was expected to be nonnil.
    public static let relationshipWasNil = RuneError("Error unwrapping this `Relationship`.")
    
    /// Couldn't sync a model; its id was nil.
    public static let syncErrorNoId = RuneError("Can't .sync() an object with a nil `id`.")
    
    /// Failed to sync a model; it didn't exist in the database.
    public static func syncErrorNoMatch<P: PrimaryKey>(table: String, id: P) -> RuneError {
        RuneError("Error syncing Model, didn't find a row with id '\(id)' on table '\(table)'.")
    }
}
