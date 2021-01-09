import NIO

/// Represents any type that can be converted into a response & is thus returnable from a `Router`
/// handler.
public protocol ResponseConvertible {
    /// Takes the response and turns it into an `EventLoopFuture<Response>`.
    ///
    /// - Throws: an error that might occur when this is turned into an `Response` future.
    /// - Returns: a future containing an `Response` to respond to a request with.
    func convert() throws -> EventLoopFuture<Response>
}

// MARK: Convenient `ResponseConvertible` Conformances.

extension Array: ResponseConvertible where Element: Encodable {
    // MARK: ResponseConvertible
    
    public func convert() throws -> EventLoopFuture<Response> {
        .new(Response(status: .ok, body: try HTTPBody(json: self)))
    }
}

extension Response: ResponseConvertible {
    // MARK: ResponseConvertible
    
    public func convert() throws -> EventLoopFuture<Response> {
        .new(self)
    }
}

extension EventLoopFuture: ResponseConvertible where Value: ResponseConvertible {
    // MARK: ResponseConvertible
    
    public func convert() throws -> EventLoopFuture<Response> {
        self.flatMap { res in
            catchError { try res.convert() }
        }
    }
}

extension String: ResponseConvertible {
    // MARK: ResponseConvertible
    
    public func convert() throws -> EventLoopFuture<Response> {
        return .new(Response(status: .ok, body: HTTPBody(text: self)))
    }
}
