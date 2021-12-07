import Foundation

/// An error related to decoding a type from a `DecodableRequest`.
public struct ValidationError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    public init(_ message: String) {
        self.message = message
    }
}

// Provide a custom response for when `ValidationError`s are thrown.
extension ValidationError: ResponseConvertible {
    public func response() throws -> Response {
        try Response(status: .badRequest)
            .withValue(["validation_error": message])
    }
}
