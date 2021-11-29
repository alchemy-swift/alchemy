import Foundation
import NIO
import NIOHTTP1

/// A type that represents inbound requests to your application.
public final class Request {
    /// The head of this request. Contains the request headers, method, URI, and
    /// HTTP version.
    public let head: HTTPRequestHead
    /// Any parameters parsed from this request's path.
    public var parameters: [Parameter] = []
    /// The remote address where this request came from.
    public var remoteAddress: SocketAddress?
    
    /// The buffer representing the body of this request.
    var bodyBuffer: ByteBuffer?
    /// Storage for values associated with this request.
    var storage: [ObjectIdentifier: Any] = [:]
    
    /// Initialize a request with the given head, body, and remote address.
    init(head: HTTPRequestHead, bodyBuffer: ByteBuffer? = nil, remoteAddress: SocketAddress?) {
        self.head = head
        self.bodyBuffer = bodyBuffer
        self.remoteAddress = remoteAddress
    }
}
