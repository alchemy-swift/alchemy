import AsyncHTTPClient
import NIO
import Foundation
import NIOHTTP1

/// The contents of an HTTP request or response.
public struct Content: ExpressibleByStringLiteral, Equatable {
    /// The default decoder for reading content from an incoming request.
    public static var defaultDecoder: ContentDecoder = .json
    /// The default encoder for writing content to an outgoing response.
    public static var defaultEncoder: ContentEncoder = .json
    
    /// The binary data in this body.
    public let buffer: ByteBuffer
    /// The content type of the data stored in this body. Used to set the
    /// `content-type` header when sending back a response.
    public let type: ContentType?
    
    /// Manages any files associated with this content.
    var _files = ContentFiles()
}

extension Content {
    /// Used to create new ByteBuffers.
    private static let allocator = ByteBufferAllocator()
    
    /// Creates a new body from a binary `NIO.ByteBuffer`.
    ///
    /// - Parameters:
    ///    - buffer: The buffer holding the data in the body.
    ///    - type: The content type of data in the body.
    public static func buffer(_ buffer: ByteBuffer, type: ContentType? = nil) -> Content {
        Content(buffer: buffer, type: type)
    }
    
    /// Creates a new body containing the text of the given string.
    ///
    /// - Parameter string: The string contents of the body.
    /// - Parameter type: The media type of this text. Defaults to
    ///   `.plainText` ("text/plain").
    public static func string(_ string: String, type: ContentType = .plainText) -> Content {
        var buffer = Content.allocator.buffer(capacity: string.utf8.count)
        buffer.writeString(string)
        return Content(buffer: buffer, type: type)
    }
    
    /// Creates a new body from a binary `Foundation.Data`.
    ///
    /// - Parameters:
    ///   - data: The data in the body.
    ///   - type: The content type of the body.
    public static func data(_ data: Data, type: ContentType? = nil) -> Content {
        var buffer = Content.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        return Content(buffer: buffer, type: type)
    }
  
    /// Creates a body with an encodable value.
    ///
    /// - Parameters:
    ///   - value: The object to encode into the body.
    ///   - encoder: A customer encoder to encoder the value with. Defaults to
    ///     `Content.defaultEncoder`.
    /// - Throws: Any error thrown during encoding.
    public static func encodable<E: Encodable>(_ value: E, encoder: ContentEncoder = Content.defaultEncoder) throws -> Content {
        try encoder.encodeContent(value)
    }

    /// Create a body via a string literal.
    ///
    /// - Parameter value: The string literal contents of the body.
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Content {
    /// The contents of this body.
    public func data() -> Data {
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
    
    /// Decodes the body as a JSON dictionary.
    ///
    /// - Throws: If there's a error decoding the dictionary.
    /// - Returns: The dictionary decoded from the contents of this
    ///   body.
    public func decodeJSONDictionary() throws -> [String: Any]? {
        try JSONSerialization.jsonObject(with: data(), options: []) as? [String: Any]
    }
    
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
        guard let decoder = decoder else {
            guard let contentType = self.type else {
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
        
        return try decoder.decodeContent(type, from: self)
    }
}
