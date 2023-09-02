/// A type representing the response from an HTTP endpoint. This response can be
/// a failure or success case depending on the status code in the `head`.
public final class Response {
    /// The success or failure status response code.
    public var status: HTTPResponseStatus
    /// The HTTP headers.
    public var headers: HTTPHeaders
    /// The body of this response. Either a stream, or a single buffer of data.
    public var body: Bytes?

    /// Creates a new response using a status code, headers, body and optional 
    /// Content-Type.
    public init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], body: Bytes? = nil, contentType: ContentType? = .octetStream, updateContentLength: Bool = true) {
        self.status = status
        self.headers = headers
        self.body = body

        if updateContentLength {
            if let body {
                self.headers.contentLength = body.length
            } else {
                self.headers.contentLength = 0
            }
        }

        if let contentType {
            self.headers.contentType = contentType
        }
    }

    /// Creates a new response using a status code, headers and `ByteBuffer` for 
    /// the body..
    public convenience init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], buffer: ByteBuffer, contentType: ContentType? = .octetStream) {
        self.init(status: status, headers: headers, body: .buffer(buffer), contentType: contentType)
    }

    /// Initialize this response with a closure that will be called, allowing
    /// you to directly write headers, body, and end to the response. The
    /// request connection will be left open until the closure finishes.
    ///
    /// Usage:
    /// ```swift
    /// app.get("/stream") {
    ///     Response(status: .ok, headers: ["Content-Length": "248"]) { writer in
    ///         writer.write(...)
    ///         writer.write(...)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter writer: A closure take a `ResponseWriter` and
    ///   using it to write response data to a remote peer.
    public convenience init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], streamer: @escaping ByteStream.Streamer, contentType: ContentType? = .octetStream) {
        self.init(status: status, headers: headers, body: .stream(streamer), contentType: contentType)
    }

    /// Creates a new body from an `Encodable`.
    public convenience init<E: Encodable>(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], encodable: E, encoder: HTTPEncoder = Bytes.defaultEncoder) throws {
        let (buffer, type) = try encoder.encodeBody(encodable)
        self.init(status: status, headers: headers, buffer: buffer, contentType: type)
    }

    /// Creates a new body from a binary `Foundation.Data`.
    public convenience init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], data: Data, contentType: ContentType? = .octetStream) throws {
        self.init(status: status, headers: headers, buffer: ByteBuffer(data: data), contentType: contentType)
    }

    /// Creates a new body containing the text of the given string.
    public convenience init(status: HTTPResponseStatus = .ok, headers: HTTPHeaders = [:], string: String, contentType: ContentType? = .plainText) {
        self.init(status: status, headers: headers, buffer: ByteBuffer(string: string), contentType: contentType)
    }

    /// Collects the body of this Response into a single `ByteBuffer`. If it is
    /// a stream, this function will return when the stream is finished. If
    /// the body is already a single `ByteBuffer`, this function will
    /// return immediately.
    @discardableResult
    public func collect() async throws -> Response {
        self.body = (try await body?.collect()).map { .buffer($0) }
        return self
    }
}
