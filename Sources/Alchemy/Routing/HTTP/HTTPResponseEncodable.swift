import NIO

/// Represents something that can be turned into an `EventLoopFuture<HTTPResponse>`.
public protocol HTTPResponseEncodable {
    /// Takes the response and turns it into an `EventLoopFuture`
    func encode() throws -> EventLoopFuture<HTTPResponse>
}

/// Conform common closure return types to HTTPResponseEncodable

extension Array: HTTPResponseEncodable where Element: Encodable {
    public func encode() throws -> EventLoopFuture<HTTPResponse> {
        Loop.future(value: HTTPResponse(status: .ok, body: try HTTPBody(json: self)))
    }
}

extension HTTPResponse: HTTPResponseEncodable {
    public func encode() throws -> EventLoopFuture<HTTPResponse> {
        Loop.future(value: self)
    }
}

extension EventLoopFuture: HTTPResponseEncodable where Value: HTTPResponseEncodable {
    public func encode() throws -> EventLoopFuture<HTTPResponse> {
        self.throwingFlatMap { try $0.encode() }
    }
}

extension String: HTTPResponseEncodable {
    public func encode() throws -> EventLoopFuture<HTTPResponse> {
        Loop.future(value: HTTPResponse(status: .ok, body: HTTPBody(text: self)))
    }
}

extension Encodable {
    public func encode() throws -> EventLoopFuture<HTTPResponse> {
        Loop.future(value: HTTPResponse(status: .ok, body: try HTTPBody(json: self)))
    }
}

/// Used as a workaround for conforming `Void` to `HTTPResponseEncodable`.
struct VoidCodable: Codable {}

extension VoidCodable: HTTPResponseEncodable {
    public func encode() throws -> EventLoopFuture<HTTPResponse> {
        Loop.future(value: HTTPResponse(status: .ok, body: try HTTPBody(json: self)))
    }
}

/// Used as a workaround for conforming `Encodable` to `HTTPResponseEncodable`.
struct CodableWrapper: Encodable, HTTPResponseEncodable {
    let obj: Encodable
    
    func encode(to encoder: Encoder) throws {
        try obj.encode(to: encoder)
    }
    
    func encode() throws -> EventLoopFuture<HTTPResponse> {
        Loop.future(value: HTTPResponse(status: .ok, body: try HTTPBody(json: self)))
    }
}
