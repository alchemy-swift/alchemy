import Foundation
import NIO
import NIOHTTP1

/// A simplified Request type as you'll come across in many web
/// frameworks
public final class Request {
    /// The default JSONDecoder with which to decode HTTP request
    /// bodies.
    public static var defaultJSONDecoder = JSONDecoder()
    
    /// The head contains all request "metadata" like the URI and
    /// request method.
    ///
    /// The headers are also found in the head, and they are often
    /// used to describe the body as well.
    public let head: HTTPRequestHead
    
    /// Any parameters inside the path.
    public var parameters: [Parameter] = []
    
    /// The bodyBuffer is internal because the HTTPBody API is exposed
    /// for easier access.
    var bodyBuffer: ByteBuffer?
    
    /// Any information set by a middleware.
    var storage: [ObjectIdentifier: Any] = [:]
    
    /// Initialize a request with the given head and body.
    init(head: HTTPRequestHead, bodyBuffer: ByteBuffer? = nil) {
        self.head = head
        self.bodyBuffer = bodyBuffer
    }
}
