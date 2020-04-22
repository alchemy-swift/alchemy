import NIO

/// Represents something that can be turned into an `EventLoopFuture<HTTPResponse>`.
public protocol HTTPResponseEncodable {
    /// Takes a response and turns it into an `EventLoopFuture`
    func encode(on eventLoop: EventLoop) throws -> EventLoopFuture<HTTPResponse>
}

struct VoidCodable: Codable {}

extension EventLoopFuture: HTTPResponseEncodable where Value == Void {
    public func encode(on eventLoop: EventLoop) throws -> EventLoopFuture<HTTPResponse> {
        self.flatMapThrowing {
            HTTPResponse(
                status: .ok,
                body: try HTTPBody(json: VoidCodable())
            )
        }
    }
}

extension String: HTTPResponseEncodable {
    public func encode(on eventLoop: EventLoop) throws -> EventLoopFuture<HTTPResponse> {
        eventLoop.makeSucceededFuture(HTTPResponse(status: .ok, body: HTTPBody(text: self)))
    }
}

extension VoidCodable: HTTPResponseEncodable {
    public func encode(on eventLoop: EventLoop) throws -> EventLoopFuture<HTTPResponse> {
        eventLoop.makeSucceededFuture(HTTPResponse(status: .ok, body: try HTTPBody(json: self)))
    }
}
