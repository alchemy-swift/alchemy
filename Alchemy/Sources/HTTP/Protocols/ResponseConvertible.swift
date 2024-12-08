/// Represents any type that can be converted into a `Response` & is thus
/// returnable from a request handler.
public protocol ResponseConvertible {
    /// Takes the type and turns it into a `Response`.
    func response() async throws -> Response
}

// MARK: Convenient `ResponseConvertible` Conformances.

extension Response: ResponseConvertible {
    public func response() -> Response {
        self
    }
}

extension String: ResponseConvertible {
    public func response() -> Response {
        Response(status: .ok, string: self)
    }
}

extension Encodable where Self: ResponseConvertible {
    public func response() throws -> Response {
        try Response(status: .ok, encodable: self)
    }
}
