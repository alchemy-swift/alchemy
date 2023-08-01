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
    
    /// Couldn't unwrap a relationship that was expected to be nonnil.
    public static func relationshipWasNil<M: Model>(type: M.Type) -> RuneError {
        RuneError("This non-optional relationship to \(type) has no matching models.")
    }
    
    /// Couldn't sync a model; its id was nil.
    public static let syncErrorNoId = RuneError("Can't .sync() an object with a nil `id`.")
    
    /// Failed to sync a model; it didn't exist in the database.
    public static func syncErrorNoMatch<P: PrimaryKey>(table: String, id: PK<P>) -> RuneError {
        let id = id.value.map { "\($0)" } ?? "nil"
        return RuneError("Error syncing Model, didn't find a row with id '\(id)' on table '\(table)'.")
    }
}
