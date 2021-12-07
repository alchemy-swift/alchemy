import NIOCore

public protocol ContentDecoder {
    func decodeContent<D: Decodable>(_ type: D.Type, from buffer: ByteBuffer, contentType: ContentType?) throws -> D
}

public protocol ContentEncoder {
    func encodeContent<E: Encodable>(_ value: E) throws -> (buffer: ByteBuffer, contentType: ContentType?)
}
