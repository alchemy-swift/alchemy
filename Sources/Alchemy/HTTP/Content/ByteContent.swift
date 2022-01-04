import AsyncHTTPClient
import NIO
import Foundation
import NIOHTTP1
import HummingbirdCore

/// A collection of bytes that is either a single buffer or a stream of buffers.
public enum ByteContent: ExpressibleByStringLiteral {
    /// The default decoder for reading content from an incoming request.
    public static var defaultDecoder: ContentDecoder = .json
    /// The default encoder for writing content to an outgoing response.
    public static var defaultEncoder: ContentEncoder = .json
    
    case buffer(ByteBuffer)
    case stream(ByteStream)
    
    public var buffer: ByteBuffer {
        switch self {
        case .stream:
            preconditionFailure("Can't synchronously access data from streaming body, try `collect()` instead.")
        case .buffer(let buffer):
            return buffer
        }
    }
    
    public var stream: ByteStream {
        switch self {
        case .stream(let stream):
            return stream
        case .buffer(let buffer):
            return .new { try await $0.write(buffer) }
        }
    }
    
    public var length: Int? {
        switch self {
        case .stream:
            return nil
        case .buffer(let buffer):
            return buffer.writerIndex
        }
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self = .buffer(ByteBuffer(string: value))
    }
    
    /// Returns the contents of the entire buffer or stream as a single buffer.
    public func collect() async throws -> ByteBuffer {
        switch self {
        case .buffer(let byteBuffer):
            return byteBuffer
        case .stream(let byteStream):
            var collection = ByteBuffer()
            try await byteStream.readAll { buffer in
                var chunk = buffer
                collection.writeBuffer(&chunk)
            }
            
            return collection
        }
    }
    
    public static func stream(_ stream: @escaping ByteStream.Closure) -> ByteContent {
        return .stream(.new(startStream: stream))
    }
}

extension File {
    @discardableResult
    mutating func collect() async throws -> File {
        self.content = .buffer(try await content.collect())
        return self
    }
}

extension Client.Response {
    @discardableResult
    public mutating func collect() async throws -> Client.Response {
        self.body = (try await body?.collect()).map { .buffer($0) }
        return self
    }
}

extension Response {
    @discardableResult
    public func collect() async throws -> Response {
        self.body = (try await body?.collect()).map { .buffer($0) }
        return self
    }
}

extension Request {
    @discardableResult
    public func collect() async throws -> Request {
        self.hbRequest.body = .byteBuffer(try await body?.collect())
        return self
    }
}

public final class ByteStream: AsyncSequence {
    public typealias Element = ByteBuffer
    public struct Writer {
        fileprivate let stream: ByteStream
        
        func write(_ chunk: Element) async throws {
            try await stream._write(chunk: chunk).get()
        }
    }
    
    public typealias Closure = (Writer) async throws -> Void
    
    private let eventLoop: EventLoop
    private let onFirstRead: ((ByteStream) -> Void)?
    private var didFirstRead: Bool
    
    var _streamer: HBByteBufferStreamer?
    
    init(eventLoop: EventLoop, onFirstRead: ((ByteStream) -> Void)? = nil) {
        self.eventLoop = eventLoop
        self.onFirstRead = onFirstRead
        self.didFirstRead = false
    }
    
    private func createStreamerIfNotExists() -> EventLoopFuture<HBByteBufferStreamer> {
        eventLoop.submit {
            guard let _streamer = self._streamer else {
                /// Don't give a max size to the underlying streamer; that will be handled elsewhere.
                let created = HBByteBufferStreamer(eventLoop: self.eventLoop, maxSize: .max, maxStreamingBufferSize: nil)
                self._streamer = created
                return created
            }

            return _streamer
        }
    }
    
    func _write(chunk: Element?) -> EventLoopFuture<Void> {
        createStreamerIfNotExists()
            .flatMap {
                if let chunk = chunk {
                    return $0.feed(buffer: chunk)
                } else {
                    $0.feed(.end)
                    return self.eventLoop.makeSucceededVoidFuture()
                }
            }
    }
    
    func _write(error: Error) {
        _ = createStreamerIfNotExists().map { $0.feed(.error(error)) }
    }
    
    func _read(on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer?> {
        createStreamerIfNotExists()
            .flatMap {
                if !self.didFirstRead {
                    self.didFirstRead = true
                    self.onFirstRead?(self)
                }
                
                return $0.consume(on: eventLoop).map { output in
                    switch output {
                    case .byteBuffer(let buffer):
                        return buffer
                    case .end:
                        return nil
                    }
                }
            }
    }
    
    public func readAll(chunkHandler: (Element) async throws -> Void) async throws {
        for try await chunk in self {
            try await chunkHandler(chunk)
        }
    }
    
    public static func new(startStream: @escaping Closure) -> ByteStream {
        ByteStream(eventLoop: Loop.current) { stream in
            Task {
                do {
                    try await startStream(Writer(stream: stream))
                    try await stream._write(chunk: nil).get()
                } catch {
                    stream._write(error: error)
                }
            }
        }
    }
    
    // MARK: - AsycIterator
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        let stream: ByteStream
        let eventLoop: EventLoop
        
        mutating public func next() async throws -> Element? {
            try await stream._read(on: eventLoop).get()
        }
    }
    
    __consuming public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(stream: self, eventLoop: eventLoop)
    }
}

extension Response {
    /// Used to create new ByteBuffers.
    private static let allocator = ByteBufferAllocator()
    
    public func withBody(_ byteContent: ByteContent, type: ContentType? = nil, length: Int? = nil) -> Response {
        body = byteContent
        headers.contentType = type
        headers.contentLength = length
        return self
    }
    
    /// Creates a new body from a binary `NIO.ByteBuffer`.
    ///
    /// - Parameters:
    ///    - buffer: The buffer holding the data in the body.
    ///    - type: The content type of data in the body.
    public func withBuffer(_ buffer: ByteBuffer, type: ContentType? = nil) -> Response {
        withBody(.buffer(buffer), type: type, length: buffer.writerIndex)
    }
    
    /// Creates a new body containing the text of the given string.
    ///
    /// - Parameter string: The string contents of the body.
    /// - Parameter type: The media type of this text. Defaults to
    ///   `.plainText` ("text/plain").
    public func withString(_ string: String, type: ContentType = .plainText) -> Response {
        var buffer = Response.allocator.buffer(capacity: string.utf8.count)
        buffer.writeString(string)
        return withBuffer(buffer, type: type)
    }
    
    /// Creates a new body from a binary `Foundation.Data`.
    ///
    /// - Parameters:
    ///   - data: The data in the body.
    ///   - type: The content type of the body.
    public func withData(_ data: Data, type: ContentType? = nil) -> Response {
        var buffer = Response.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        return withBuffer(buffer, type: type)
    }
    
    /// Creates a new body from an `Encodable`.
    ///
    /// - Parameters:
    ///   - data: The data in the body.
    ///   - type: The content type of the body.
    public func withValue<E: Encodable>(_ value: E, encoder: ContentEncoder = ByteContent.defaultEncoder) throws -> Response {
        let (buffer, type) = try encoder.encodeContent(value)
        return withBuffer(buffer, type: type)
    }
}

extension ByteContent {
    /// The contents of this body.
    public func data() -> Data {
        guard case let .buffer(buffer) = self else {
            preconditionFailure("Can't synchronously access data from streaming body, try `collect()` instead.")
        }
        
        return buffer.withUnsafeReadableBytes { buffer -> Data in
            let buffer = buffer.bindMemory(to: UInt8.self)
            return Data.init(buffer: buffer)
        }
    }
    
    /// Decodes the body as a `String`.
    ///
    /// - Parameter encoding: The `String.Encoding` value to decode
    ///   with. Defaults to `.utf8`.
    /// - Returns: The string decoded from the contents of this body.
    public func string(with encoding: String.Encoding = .utf8) -> String? {
        String(data: data(), encoding: encoding)
    }
    
    public static func string(_ string: String) -> ByteContent {
        .buffer(ByteBuffer(string: string))
    }
    
    public static func data(_ data: Data) -> ByteContent {
        .buffer(ByteBuffer(data: data))
    }
    
    public static func value<E: Encodable>(_ value: E, encoder: ContentEncoder = ByteContent.defaultEncoder) throws -> ByteContent {
        .buffer(try encoder.encodeContent(value).buffer)
    }
    
    public static func json(_ dict: [String: Any?]) throws -> ByteContent {
        .buffer(ByteBuffer(data: try JSONSerialization.data(withJSONObject: dict)))
    }
    
    /// Decodes the body as a JSON dictionary.
    ///
    /// - Throws: If there's a error decoding the dictionary.
    /// - Returns: The dictionary decoded from the contents of this
    ///   body.
    public func decodeJSONDictionary() throws -> [String: Any]? {
        try JSONSerialization.jsonObject(with: data(), options: []) as? [String: Any]
    }
}
