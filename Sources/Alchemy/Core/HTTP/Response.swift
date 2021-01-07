import NIO
import NIOHTTP1

/// A type representing the response from an HTTP endpoint. This response can be a failure or
/// success case depending on the status code in the `head`.
public final class Response {
    /// The default `JSONEncoder` with which to encode JSON responses.
    public static var defaultJSONEncoder = JSONEncoder()
    
    /// The default response for when there is an error along the routing chain that does not
    /// conform to `ResponseConvertible`.
    public static var defaultErrorResponse = Response(
        status: .internalServerError,
        body: HTTPBody(text: "Server error")
    )
    
    /// The success or failure status response code.
    public var status: HTTPResponseStatus
    
    /// The HTTP headers.
    public var headers: HTTPHeaders

    /// The body which contains any data you want to send back to the client
    /// This can be HTML, an image or JSON among many other data types.
    public let body: HTTPBody?
    
    /// This will be called (potentially repeatedly) while this `Response` writes data to a
    /// remote peer.
    internal var writerClosure: (ResponseWriter) -> Void {
        get { self._writerClosure ?? self.defaultWriterClosure }
    }
    
    /// Closure for deferring writing
    private var _writerClosure: ((ResponseWriter) -> Void)?
  
    /// Creates a new response using a status code, headers and body. If the headers do not contain
    /// `content-length` or `content-type`, those will be appended based on the supplied `HTTPBody`.
    ///
    /// - Parameters:
    ///   - status: The status code of this response.
    ///   - headers: any headers to return in the response. Defaults to empty headers.
    ///   - body: the body of this response. See `HTTPBody` for initializing with various data.
    public init(status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders(), body: HTTPBody?) {
        var headers = headers
        headers.replaceOrAdd(name: "content-length", value: String(body?.buffer.writerIndex ?? 0))
        body?.mimeType.map { headers.replaceOrAdd(name: "content-type", value: $0.value) }
        
        self.status = status
        self.headers = headers
        self.body = body
    }
    
    /// Initialize this response with a closure that will be called, allowing you to directly write
    /// headers, body, and end to the response. The request connection will be left open until you
    /// `.writeEnd()` to the closure's `ResponseWriter`.
    ///
    /// Usage:
    /// ```
    /// router.on(.GET, "/stream") {
    ///     Response { writer in
    ///         writer.writeHead(...)
    ///         writer.writeBody(...)
    ///         writer.writeEnd()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter writer: A closure take a `ResponseWriter` and using it to write response data to
    ///                     a remote peer.
    public init(_ writer: @escaping (ResponseWriter) -> Void) {
        self.status = .ok
        self.headers = HTTPHeaders()
        self.body = nil
        self._writerClosure = writer
    }
    
    /// Writes this response to an remote peer via a `ResponseWriter`.
    ///
    /// - Parameter writer: An abstraction around writing data to a remote peer.
    func write(to writer: ResponseWriter) {
        self.writerClosure(writer)
    }
    
    /// Provides default writing behavior for a `Response`.
    ///
    /// - Parameter writer: An abstraction around writing data to a remote peer.
    private func defaultWriterClosure(writer: ResponseWriter) {
        writer.writeHead(status: self.status, self.headers)
        if let body = self.body {
            writer.writeBody(body.buffer)
        }
        writer.writeEnd()
    }
}

/// An abstraction around writing data to a remote peer. Conform to this protocol and inject it into
/// the `Response` for responding to a remote peer at a later point in time.
///
/// Be sure to call `writeEnd` when you are finished writing data or the client response will never
/// complete.
public protocol ResponseWriter {
    /// Write the status and head of a response. Should only be called once.
    ///
    /// - Parameters:
    ///   - status: The status code of the response.
    ///   - headers: Any headers of this response.
    func writeHead(status: HTTPResponseStatus, _ headers: HTTPHeaders)
    
    /// Write some body data to the remote peer. May be called 0 or more times.
    ///
    /// - Parameter body: The buffer of data to write.
    func writeBody(_ body: ByteBuffer)
    
    /// Write the end of the response. Needs to be called once per response, when all data has been
    /// written.
    func writeEnd()
}

extension ResponseWriter {
    // Convenience default parameters for `writeHead`.
    public func writeHead(status: HTTPResponseStatus = .ok, _ headers: HTTPHeaders = HTTPHeaders()) {
        self.writeHead(status: status, headers)
    }
}
