struct DatabaseDecodingError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}
