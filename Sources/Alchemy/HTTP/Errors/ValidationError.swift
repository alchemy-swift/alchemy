import Foundation

/// An error related to decoding a type from a `DecodableRequest`.
public struct ValidationError: Error, ResponseConvertible {
    /// What went wrong.
    public let message: String
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    public init(_ message: String) {
        self.message = message
    }

    // MARK: ResponseConvertible

    public func response() throws -> Response {
        try Response(status: .badRequest, encodable: ["validation_error": message])
    }
}
