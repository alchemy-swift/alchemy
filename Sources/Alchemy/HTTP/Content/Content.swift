import AsyncHTTPClient
import NIO
import Foundation
import NIOHTTP1

/// A collection of bytes that is either a single buffer or a stream of buffers.
public enum ByteContent: ExpressibleByStringLiteral {
    case buffer(ByteBuffer)
    case stream(ByteStream)
    
    var buffer: ByteBuffer {
        switch self {
        case .stream:
            preconditionFailure("Can't synchronously access data from streaming body, try `collect()` instead.")
        case .buffer(let buffer):
            return buffer
        }
    }
    
    var stream: ByteStream {
        switch self {
        case .stream(let stream):
            return stream
        case .buffer(let buffer):
            return .new { try await $0(buffer) }
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
            try await byteStream.read { buffer in
                var chunk = buffer
                collection.writeBuffer(&chunk)
            }
            return collection
        }
    }
    
    public static func stream(_ stream: @escaping ByteStreamClosure) -> ByteContent {
        return .stream(ByteStream(write: stream, readChunk: nil))
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

/*
 Stream
 1. Write
   i. outgoing response
   ii. outgoing Client.request
   iii. file write
 2. Read
   i. incoming request
   ii. incoming Client.response
   iii. file read
 */
/// A stream of bytes. When this closure completes; the stream is finished.
public typealias ByteStreamClosure = (@escaping ByteStream.Writer) async throws -> Void
public struct ByteStream {
    public typealias Writer = (ByteBuffer) async throws -> Void
    
    let write: ByteStreamClosure?
    
    public func read(_ handler: @escaping (ByteBuffer) async throws -> Void) async throws {
        try await write?(handler)
    }
    
    public static func new(_ stream: @escaping ByteStreamClosure) -> ByteStream {
        self.init(write: stream, readChunk: nil)
    }
    
    /// Need this since hummingbird streaming puts the responsibility of
    /// initiating sending the next chunk on the consumer, not the
    /// producer. Therefore there needs to be a way to send a
    /// chunk without sending the next one after the first
    /// is read.
    public typealias Read = () async throws -> ByteBuffer?
    
    let readChunk: Read?
    
    func readNext() async throws -> ByteBuffer? {
        return try await self.readChunk?()
    }
    
    public static func chunkReadable(_ stream: @escaping Read) -> ByteStream {
        self.init(write: nil, readChunk: stream)
    }
}

extension Response {
    /// Used to create new ByteBuffers.
    private static let allocator = ByteBufferAllocator()
    
    public func withBody(_ byteContent: ByteContent, type: ContentType? = nil) -> Response {
        body = byteContent
        headers.contentType = type
        return self
    }
    
    /// Creates a new body from a binary `NIO.ByteBuffer`.
    ///
    /// - Parameters:
    ///    - buffer: The buffer holding the data in the body.
    ///    - type: The content type of data in the body.
    public func withBuffer(_ buffer: ByteBuffer, type: ContentType? = nil) -> Response {
        headers.contentLength = buffer.writerIndex
        return withBody(.buffer(buffer), type: type)
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
  
    /// Creates a body with an encodable value.
    ///
    /// - Parameters:
    ///   - value: The object to encode into the body.
    ///   - encoder: A customer encoder to encoder the value with. Defaults to
    ///     `Content.defaultEncoder`.
    /// - Throws: Any error thrown during encoding.
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
    
    public func value<E: Encodable>(_ value: E, encoder: ContentEncoder = Content.defaultEncoder) throws -> ByteContent {
        .buffer(try encoder.encodeContent(value).buffer)
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

extension Request: ContentConvertible {}
extension Response: ContentConvertible {}

public protocol ContentConvertible {
    var headers: HTTPHeaders { get }
    var body: ByteContent? { get }
}

extension ContentConvertible {
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
            case .urlEncoded:
                return try decode(as: type, with: .url)
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
