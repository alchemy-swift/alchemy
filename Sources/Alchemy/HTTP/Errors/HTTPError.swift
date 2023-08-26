import NIOHTTP1

/// An HTTPError that can be thrown during routing. When intercepted,
/// Alchemy will return an error response with the status code of
/// this error and a body containing the message, if there is one.
///
/// Note that if you conform your own, custom `Error`s to
/// `ResponseConvertible`, they will be converted to that response if
/// they are thrown during the `Router` chain.
///
/// Usage:
/// ```swift
/// app.post("/error") {
///     // Client will see a 501 response status with body
///     // { "message": "This endpoint isn't implemented yet" }
///     throw HTTPError(.notImplemented, "This endpoint isn't implemented yet")
/// }
/// ```
public struct HTTPError: Error, ResponseConvertible {
    /// The status code of this error.
    public let status: HTTPResponseStatus
    /// An optional message to include in a
    public let message: String?
    
    /// Create the error with a custom `HTTPResponseStatus` and
    /// optional message.
    ///
    /// - Parameters:
    ///   - status: The status code of this error.
    ///   - message: The message associated with this error, defaults
    ///     to nil.
    public init(_ status: HTTPResponseStatus, message: String? = nil) {
        self.status = status
        self.message = message
    }

    // MARK: ResponseConvertible

    public func response() throws -> Response {
        try Response(status: status, encodable: ["message": message ?? status.reasonPhrase])
    }
}
