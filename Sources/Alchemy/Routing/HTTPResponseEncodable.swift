import NIO

/// Represents any type that can be encoded into a response & is thus returnable from a `HTTPRouter`
/// routing closure.
public protocol HTTPResponseEncodable {
    /// Takes the response and turns it into an `EventLoopFuture<Response>`.
    ///
    /// - Throws: an error that might occur when this is turned into an `Response` future.
    /// - Returns: a future containing an `Response` to respond to a request with.
    func encode() throws -> EventLoopFuture<Response>
}

// MARK: Convenient `HTTPResponseEncodable` Conformances.

extension Array: HTTPResponseEncodable where Element: Encodable {
    // MARK: HTTPResponseEncodable
    
    public func encode() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: try HTTPBody(json: self)))
    }
}

extension Response: HTTPResponseEncodable {
    // MARK: HTTPResponseEncodable
    
    public func encode() throws -> EventLoopFuture<Response> {
        .new(self)
    }
}

extension EventLoopFuture: HTTPResponseEncodable where Value: HTTPResponseEncodable {
    // MARK: HTTPResponseEncodable
    
    public func encode() throws -> EventLoopFuture<Response> {
        self.flatMap { res in
            catchError { try res.encode() }
        }
    }
}

extension String: HTTPResponseEncodable {
    // MARK: HTTPResponseEncodable
    
    public func encode() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: HTTPBody(text: self)))
    }
}
