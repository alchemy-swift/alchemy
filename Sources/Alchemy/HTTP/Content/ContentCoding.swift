import NIOCore

/// The contents of an HTTP request or response.
public struct Content {
    /// The default decoder for reading content from an incoming request.
    public static var defaultDecoder: ContentDecoder = .json
    /// The default encoder for writing content to an outgoing response.
    public static var defaultEncoder: ContentEncoder = .json
    
    /// The binary data in this body.
    public let buffer: ByteBuffer
    /// The content type of the data stored in this body. Used to set the
    /// `content-type` header when sending back a response.
    public let type: ContentType?
}

public protocol ContentDecoder {
    func decodeContent<D: Decodable>(_ type: D.Type, from content: Content) throws -> D
}

public protocol ContentEncoder {
    func encodeContent<E: Encodable>(_ value: E) throws -> Content
}
