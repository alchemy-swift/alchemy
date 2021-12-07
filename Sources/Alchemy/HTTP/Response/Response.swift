import NIO
import NIOHTTP1

/// A type representing the response from an HTTP endpoint. This
/// response can be a failure or success case depending on the
/// status code in the `head`.
public final class Response {
    /// The success or failure status response code.
    public var status: HTTPResponseStatus
    /// The HTTP headers.
    public var headers: HTTPHeaders
    /// The body of this response.
    public var body: ByteContent?
    
    /// Creates a new response using a status code, headers and body. If the
    /// body is of type `.buffer()` or `nil`, the `Content-Length` header
    /// will be set, if not already, in the headers.
    ///
    /// - Parameters:
    ///   - status: The status of this response.
    ///   - headers: Any headers for this response.
    ///   - body: Any response body, either a buffer or streamed.
    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], body: ByteContent? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
        
        switch body {
        case .buffer(let buffer):
            self.headers.contentLength = buffer.writerIndex
        case .none:
            self.headers.contentLength = 0
        default:
            break
        }
    }
    
    /// Initialize this response with a closure that will be called,
    /// allowing you to directly write headers, body, and end to
    /// the response. The request connection will be left open
    /// until you `.writeEnd()` to the closure's
    /// `ResponseWriter`.
    ///
    /// Usage:
    /// ```swift
    /// app.get("/stream") {
    ///     Response(status: .ok, headers: ["Content-Length": "248"]) { writer in
    ///         writer.writeHead(...)
    ///         writer.writeBody(...)
    ///         writer.writeEnd()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter writer: A closure take a `ResponseWriter` and
    ///   using it to write response data to a remote peer.
    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], stream: @escaping ByteStream.Closure) {
        self.status = .ok
        self.headers = HTTPHeaders()
        self.body = .stream(stream)
    }
}
