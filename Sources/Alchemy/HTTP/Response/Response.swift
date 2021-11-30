import NIO
import NIOHTTP1

/// A type representing the response from an HTTP endpoint. This
/// response can be a failure or success case depending on the
/// status code in the `head`.
public final class Response {
    public typealias WriteResponse = (ResponseWriter) async throws -> Void
    
    /// The success or failure status response code.
    public var status: HTTPResponseStatus
    /// The HTTP headers.
    public var headers: HTTPHeaders
    /// The body of this response.
    public let body: Content?
    
    /// This will be called when this `Response` writes data to a
    /// remote peer.
    fileprivate var writerClosure: WriteResponse {
        get { _writerClosure ?? defaultWriterClosure }
    }
    
    /// Closure for deferring writing.
    private var _writerClosure: WriteResponse?
  
    /// Creates a new response using a status code, headers and body.
    /// If the headers do not contain `content-length` or
    /// `content-type`, those will be appended based on
    /// the supplied `HTTPBody`.
    ///
    /// - Parameters:
    ///   - status: The status code of this response.
    ///   - headers: Any headers to return in the response. Defaults
    ///     to empty headers.
    ///   - body: The body of this response. See `HTTPBody` for
    ///     initializing with various data. Defaults to nil.
    public init(status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders(), body: Content? = nil) {
        var headers = headers
        headers.replaceOrAdd(name: "content-length", value: String(body?.buffer.writerIndex ?? 0))
        body?.contentType.map { headers.replaceOrAdd(name: "content-type", value: $0.value) }
        
        self.status = status
        self.headers = headers
        self.body = body
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
    ///     Response { writer in
    ///         writer.writeHead(...)
    ///         writer.writeBody(...)
    ///         writer.writeEnd()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter writer: A closure take a `ResponseWriter` and
    ///   using it to write response data to a remote peer.
    public init(_ writeResponse: @escaping WriteResponse) {
        self.status = .ok
        self.headers = HTTPHeaders()
        self.body = nil
        self._writerClosure = writeResponse
    }
    
    /// Provides default writing behavior for a `Response`.
    ///
    /// - Parameter writer: An abstraction around writing data to a
    ///   remote peer.
    private func defaultWriterClosure(writer: ResponseWriter) async throws {
        try await writer.writeHead(status: status, headers)
        if let body = body {
            try await writer.writeBody(body.buffer)
        }
        
        try await writer.writeEnd()
    }
}

extension Response {
    func collect() async throws -> Response {
        final class MockWriter: ResponseWriter {
            var status: HTTPResponseStatus = .ok
            var headers: HTTPHeaders = [:]
            var body = ByteBuffer()
            
            func writeHead(status: HTTPResponseStatus, _ headers: HTTPHeaders) {
                self.status = status
                self.headers = headers
            }
            
            func writeBody(_ body: ByteBuffer) {
                self.body.writeBytes(body.readableBytesView)
            }
            
            func writeEnd() async throws {}
        }

        let writer = MockWriter()
        try await writer.write(response: self)
        return Response(status: writer.status, headers: writer.headers, body: Content(buffer: writer.body))
    }
}

extension ResponseWriter {
    /// Writes a response to a remote peer with this `ResponseWriter`.
    ///
    /// - Parameter response: The response to write.
    func write(response: Response) async throws {
        try await response.writerClosure(self)
    }
}
