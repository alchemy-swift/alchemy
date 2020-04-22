import NIO
import NIOHTTP1

/// A simplified HTTPRequest type as you'll come across in many web frameworks
public struct HTTPRequest {
    /// The EventLoop is stored in the HTTP request so that promises can be created
    public let eventLoop: EventLoop
    
    /// The head contains all request "metadata" like the URI and request method
    ///
    /// The headers are also found in the head, and they are often used to describe the body as well
    public let head: HTTPRequestHead
    
    /// The bodyBuffer is internal because the HTTPBody API is exposed for simpler access
    var bodyBuffer: ByteBuffer?
    
    /// This initializer is necessary because the `bodyBuffer` is a private property
    init(eventLoop: EventLoop, head: HTTPRequestHead, bodyBuffer: ByteBuffer?) {
        self.eventLoop = eventLoop
        self.head = head
        self.bodyBuffer = bodyBuffer
    }
    
    /// The body is a wrapped used to provide simpler access to body data like JSON
    public var body: HTTPBody? {
        guard let bodyBuffer = bodyBuffer else {
            return nil
        }
        
        return HTTPBody(buffer: bodyBuffer)
    }
}
