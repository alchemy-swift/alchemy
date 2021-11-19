import NIO
import NIOHTTP1

/// Responds to incoming `Request`s with an `Response` generated by a handler.
final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
  
    // Indicates that the TCP connection needs to be closed after a
    // response has been sent.
    private var keepAlive = true
  
    /// A temporary local Request that is used to accumulate data
    /// into.
    private var request: Request?
  
    /// The responder to all requests.
    private let handler: (Request) async -> Response
    
    /// Initialize with a handler to respond to all requests.
    ///
    /// - Parameter handler: The object to respond to all incoming
    ///   `Request`s.
    init(handler: @escaping (Request) async -> Response) {
        self.handler = handler
    }
    
    /// Received incoming `InboundIn` data, writing a response based
    /// on the `Responder`.
    ///
    /// - Parameters:
    ///   - context: The context of the handler.
    ///   - data: The inbound data received.
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let requestHead):
            // If the part is a `head`, a new Request is received
            keepAlive = requestHead.isKeepAlive
      
            let contentLength: Int
      
            // We need to check the content length to reserve memory
            // for the body
            if let length = requestHead.headers["content-length"].first {
                contentLength = Int(length) ?? 0
            } else {
                contentLength = 0
            }
      
            let body: ByteBuffer?
      
            // Allocates the memory for accumulation
            if contentLength > 0 {
                body = context.channel.allocator.buffer(capacity: contentLength)
            } else {
                body = nil
            }
      
            request = Request(head: requestHead, bodyBuffer: body)
        case .body(var newData):
            // Appends new data to the already reserved buffer
            request?.bodyBuffer?.writeBuffer(&newData)
        case .end:
            guard let request = request else {
                return
            }
            
            self.request = nil

            // Writes the response when done
            _ = context.eventLoop
                .wrapAsync {
                    try await self.writeResponse(
                        version: request.head.version,
                        response: await self.handler(request),
                        to: context)
                }
        }
    }
  
    /// Writes the `Responder`'s `Response` to a
    /// `ChannelHandlerContext`.
    ///
    /// - Parameters:
    ///   - version: The HTTP version of the connection.
    ///   - response: The reponse to write to the handler context.
    ///   - context: The context to write to.
    /// - Returns: A handle for the task of writing the response.
    private func writeResponse(version: HTTPVersion, response: Response, to context: ChannelHandlerContext) async throws {
        try await HTTPResponseWriter(version: version, handler: self, context: context).write(response: response)
        if !self.keepAlive {
            try await context.close()
        }
    }
    
    /// Handler for when the channel read is complete.
    ///
    /// - Parameter context: the context to send events to.
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
}

/// Used for writing a response to a remote peer with an
/// `HTTPHandler`.
private struct HTTPResponseWriter: ResponseWriter {
    /// The HTTP version we're working with.
    private var version: HTTPVersion
    
    /// The handler in which this writer is writing.
    private let handler: HTTPHandler
    
    /// The context that should be written to.
    private let context: ChannelHandlerContext
    
    /// Initialize
    /// - Parameters:
    ///   - version: The HTTPVersion of this connection.
    ///   - handler: The handler in which this response is writing
    ///     inside.
    ///   - context: The context to write responses to.
    init(version: HTTPVersion, handler: HTTPHandler, context: ChannelHandlerContext) {
        self.version = version
        self.handler = handler
        self.context = context
    }
    
    // MARK: ResponseWriter
    
    func writeHead(status: HTTPResponseStatus, _ headers: HTTPHeaders) async throws {
        let head = HTTPResponseHead(version: version, status: status, headers: headers)
        _ = context.eventLoop.execute {
            context.write(handler.wrapOutboundOut(.head(head)), promise: nil)
        }
    }
    
    func writeBody(_ body: ByteBuffer) async throws {
        _ = context.eventLoop.execute {
            context.writeAndFlush(handler.wrapOutboundOut(.body(IOData.byteBuffer(body))), promise: nil)
        }
    }
    
    func writeEnd() async throws {
        _ = context.eventLoop.execute {
            context.writeAndFlush(handler.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}
