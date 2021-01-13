import NIO

/// Represents any type that can be converted into a response & is
/// thus returnable from a request handler.
public protocol ResponseConvertible {
    /// Takes the response and turns it into an
    /// `EventLoopFuture<Response>`.
    ///
    /// - Throws: Any error that might occur when this is turned into
    ///   a `Response` future.
    /// - Returns: A future containing an `Response` to respond to a
    ///   `Request` with.
    func convert() throws -> EventLoopFuture<Response>
}

// MARK: Convenient `ResponseConvertible` Conformances.

extension Array: ResponseConvertible where Element: Encodable {
    public func convert() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: try HTTPBody(json: self)))
    }
}

extension Response: ResponseConvertible {
    public func convert() throws -> EventLoopFuture<Response> {
        .new(self)
    }
}

extension EventLoopFuture: ResponseConvertible where Value: ResponseConvertible {
    public func convert() throws -> EventLoopFuture<Response> {
        self.flatMap { res in
            catchError { try res.convert() }
        }
    }
}

extension String: ResponseConvertible {
    public func convert() throws -> EventLoopFuture<Response> {
        return .new(Response(status: .ok, body: HTTPBody(text: self)))
    }
}

// Sadly `Swift` doesn't allow a protocol to conform to another
// protocol in extensions, but we can at least add the
// implementation here (and a special case router
// `.on` specifically for `Encodable`) types.
extension Encodable {
    public func encode() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: try HTTPBody(json: self)))
    }
}
