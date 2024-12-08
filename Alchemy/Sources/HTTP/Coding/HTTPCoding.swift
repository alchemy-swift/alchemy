/// Decodes a type from an HTTP message (Response or Request) body.
public protocol HTTPDecoder {
    func decodeBody<D: Decodable>(_ type: D.Type, from buffer: ByteBuffer, contentType: ContentType?) throws -> D
    func content(from buffer: ByteBuffer, contentType: ContentType?) -> Content
}

/// Encodes a type into the info required for an HTTP message (Response or
/// Request) body.
public protocol HTTPEncoder {
    func encodeBody<E: Encodable>(_ value: E) throws -> (buffer: ByteBuffer, contentType: ContentType?)
}
