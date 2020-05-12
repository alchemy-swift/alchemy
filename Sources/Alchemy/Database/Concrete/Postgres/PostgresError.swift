public struct PostgresError: Error {
    public let message: String
    
    init(_ message: String) {
        self.message = message
    }
}
