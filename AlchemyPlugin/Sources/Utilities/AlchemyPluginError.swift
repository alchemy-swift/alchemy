struct AlchemyMacroError: Error, CustomDebugStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var debugDescription: String {
        message
    }
}
