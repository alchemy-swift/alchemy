import AsyncHTTPClient
import NIO
import Foundation
import NIOHTTP1

/// A collection of bytes that is either a single buffer or a stream of buffers.
public enum ByteContent: ExpressibleByStringLiteral {
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

extension Client.Response {
    @discardableResult
    mutating func collect() async throws -> Client.Response {
        self.body = (try await body?.collect()).map { .buffer($0) }
        return self
    }
}

extension Response {
    @discardableResult
    func collect() async throws -> Response {
        self.body = (try await body?.collect()).map { .buffer($0) }
        return self
    }
}

extension Request {
    @discardableResult
    func collect() async throws -> Request {
        self.hbRequest.body = .byteBuffer(try await body?.collect())
        return self
    }
}

public typealias ByteStream = Stream<ByteBuffer>

// Streams can be written to and read.
// Streams can be written to all at once or one at a time.
// Streams can be read all at once or one at a time.
public final class Stream<Element>: AsyncSequence {
    public struct Writer {
        fileprivate let stream: Stream<Element>
        
        func write(_ chunk: Element) async throws {
            try await stream._write(chunk: chunk).get()
        }
    }
    
    public typealias Closure = (Writer) async throws -> Void
    
    private let eventLoop: EventLoop
    private var readPromise: EventLoopPromise<Void>
    private var writePromise: EventLoopPromise<Element?>
    private let onFirstRead: ((Stream<Element>) -> Void)?
    private var didFirstRead: Bool
    
    deinit {
        readPromise.succeed(())
        writePromise.succeed(nil)
    }
    
    init(eventLoop: EventLoop, onFirstRead: ((Stream<Element>) -> Void)? = nil) {
        self.eventLoop = eventLoop
        self.readPromise = eventLoop.makePromise(of: Void.self)
        self.writePromise = eventLoop.makePromise(of: Element?.self)
        self.onFirstRead = onFirstRead
        self.didFirstRead = false
    }
    
    func _write(chunk: Element?) -> EventLoopFuture<Void> {
        writePromise.succeed(chunk)
        // Wait until the chunk is read.
        return readPromise.futureResult
            .map {
                if chunk != nil {
                    self.writePromise = self.eventLoop.makePromise(of: Element?.self)
                }
            }
    }
    
    func _write(error: Error) {
        writePromise.fail(error)
        readPromise.fail(error)
    }
    
    func _read(on eventLoop: EventLoop) -> EventLoopFuture<Element?> {
        return eventLoop
            .submit {
                if !self.didFirstRead {
                    self.didFirstRead = true
                    self.onFirstRead?(self)
                }
            }
            .flatMap {
                // Wait until a chunk is written.
                self.writePromise.futureResult
                    .map { chunk in
                        let old = self.readPromise
                        if chunk != nil {
                            self.readPromise = eventLoop.makePromise(of: Void.self)
                        }
                        old.succeed(())
                        return chunk
                    }
            }
    }
    
    public func readAll(chunkHandler: (Element) async throws -> Void) async throws {
        for try await chunk in self {
            try await chunkHandler(chunk)
        }
    }
    
    public static func new(startStream: @escaping Closure) -> Stream<Element> {
        Stream<Element>(eventLoop: Loop.current) { stream in
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
        let stream: Stream
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
    public func withValue<E: Encodable>(_ value: E, encoder: ContentEncoder = Content.defaultEncoder) throws -> Response {
        let content = try encoder.encodeContent(value)
        return withBuffer(content.buffer, type: content.type)
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
    
    public static func value<E: Encodable>(_ value: E, encoder: ContentEncoder = Content.defaultEncoder) throws -> ByteContent {
        .buffer(try encoder.encodeContent(value).buffer)
    }
    
    public static func jsonDict(_ dict: [String: Any?]) throws -> ByteContent {
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

extension Request: HasContent {}
extension Response: HasContent {}

/// A type, likely an HTTP request or response, that has body content.
public protocol HasContent {
    var headers: HTTPHeaders { get }
    var body: ByteContent? { get }
}

extension HasContent {
    /// Decodes the content as a decodable, based on it's content type or with
    /// the given content decoder.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to which the body should be decoded.
    ///   - decoder: The decoder with which to decode. Defaults to
    ///     `Content.defaultDecoder`.
    /// - Throws: Any errors encountered during decoding.
    /// - Returns: The decoded object of type `type`.
    public func decode<D: Decodable>(as type: D.Type = D.self, with decoder: ContentDecoder? = nil) throws -> D {
        guard let buffer = body?.buffer else {
            throw ValidationError("expecting a request body")
        }
        
        guard let decoder = decoder else {
            guard let contentType = self.headers.contentType else {
                return try decode(as: type, with: Content.defaultDecoder)
            }
            
            switch contentType {
            case .json:
                return try decode(as: type, with: .json)
            case .urlForm:
                return try decode(as: type, with: .urlForm)
            case .multipart(boundary: ""):
                return try decode(as: type, with: .multipart)
            default:
                throw HTTPError(.notAcceptable)
            }
        }
        
        let content = Content(buffer: buffer, type: headers.contentType)
        return try decoder.decodeContent(type, from: content)
    }
}
