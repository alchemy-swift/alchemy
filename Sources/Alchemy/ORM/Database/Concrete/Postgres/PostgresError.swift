public struct PostgresError: Error {
    public let message: String
    
    static func unwrapError(_ expectedType: String, column: String) -> PostgresError {
        PostgresError(message: "Unable to unwrap expected type `\(expectedType)` from column '\(column)'.")
    }
}
