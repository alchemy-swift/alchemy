import AsyncHTTPClient
import NIO
import Foundation
import NIOHTTP1

/// The contents of an HTTP request or response.
public struct HTTPBody: ExpressibleByStringLiteral {
    /// Used to create new ByteBuffers.
    private static let allocator = ByteBufferAllocator()
    
    /// The binary data in this body.
    let buffer: ByteBuffer
    
    /// The mime type of the data stored in this body. Used to set the
    /// `content-type` header when sending back a response.
    public let mimeType: String?
    
    /// Creates a new body from a binary `NIO.ByteBuffer`.
    ///
    /// - Parameters:
    ///    - buffer: the buffer holding the data in the body.
    ///    - mimeType: the MIME type of data in the body.
    public init(buffer: ByteBuffer, mimeType: String? = nil) {
        self.buffer = buffer
        self.mimeType = mimeType
    }
     
    /// Creates a new body containing the text with MIME type `text/plain`.
    ///
    /// - Parameter text: the string contents of the body.
    public init(text: String) {
        var buffer = HTTPBody.allocator.buffer(capacity: text.utf8.count)
        buffer.writeString(text)
        self.buffer = buffer
        self.mimeType = "text/plain"
    }
    
    /// Creates a new body from a binary `Foundation.Data`.
    ///
    /// - Parameters:
    ///   - data: the data in the body.
    ///   - mimeType: the MIME type of the body.
    public init(data: Data, mimeType: String? = nil) {
        var buffer = HTTPBody.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        self.buffer = buffer
        self.mimeType = mimeType
    }
  
    /// Creates a body with a JSON object.
    ///
    /// - Parameters:
    ///   - json: the object to encode into the body.
    ///   - encoder: a customer encoder to encoder the JSON with. Defaults to
    ///              `HTTPResponse.defaultJSONEncoder`.
    /// - Throws: Any error thrown during encoding.
    public init<E: Encodable>(
        json: E,
        encoder: JSONEncoder = HTTPResponse.defaultJSONEncoder
    ) throws {
        let data = try HTTPResponse.defaultJSONEncoder.encode(json)
        self.init(data: data, mimeType: "application/json")
    }

    /// Create a body via a string literal.
    ///
    /// - Parameter value: the string literal contents of the body.
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
    
    /// The contents of this body.
    public var data: Data {
        return buffer.withUnsafeReadableBytes { buffer -> Data in
            let buffer = buffer.bindMemory(to: UInt8.self)
            return Data.init(buffer: buffer)
        }
    }
}

extension HTTPBody {
    /// Decodes the body as a `String`.
    ///
    /// - Parameter encoding: the `String.Encoding` value to decode with.
    ///                       Defaults to `.utf8`.
    /// - Returns: the string decoded from the contents of this body.
    public func decodeString(with encoding: String.Encoding = .utf8) -> String?
    {
        String(data: self.data, encoding: encoding)
    }
    
    /// Decodes the body as a JSON dictionary.
    ///
    /// - Throws: if there's a error decoding the dictionary.
    /// - Returns: the dictionary decoded from the contents of this body.
    public func decodeJSONDictionary() throws -> [String: Any]? {
        try JSONSerialization.jsonObject(with: self.data, options: [])
            as? [String: Any]
    }
    
    /// Decodes the body as JSON into the provided Decodable type.
    ///
    /// - Parameters:
    ///   - type: the Decodable type to which the body should be decoded.
    ///   - decoder: the Decoder with which to decode. Defaults to
    ///              `HTTPRequest.defaultJSONEncoder`.
    /// - Throws: any errors encountered during decoding.
    /// - Returns: the decoded object of type `type`.
    public func decodeJSON<D: Decodable>(
        as type: D.Type = D.self,
        with decoder: JSONDecoder = HTTPRequest.defaultJSONDecoder
    ) throws -> D {
        return try decoder.decode(type, from: data)
    }
}
