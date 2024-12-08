struct AlchemyMacroError: Error, CustomDebugStringConvertible, ExpressibleByStringInterpolation {
    let message: String

    var debugDescription: String {
        message
    }

    init(_ message: String) {
        self.message = message
    }

    init(stringLiteral value: String) {
        self.init(value)
    }
}
