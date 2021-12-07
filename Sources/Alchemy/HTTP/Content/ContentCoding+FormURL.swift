import HummingbirdFoundation

extension ContentEncoder where Self == URLEncodedFormEncoder {
    public static var urlForm: URLEncodedFormEncoder { URLEncodedFormEncoder() }
}

extension ContentDecoder where Self == URLEncodedFormDecoder {
    public static var urlForm: URLEncodedFormDecoder { URLEncodedFormDecoder() }
}

extension URLEncodedFormEncoder: ContentEncoder {
    public func encodeContent<E>(_ value: E) throws -> (buffer: ByteBuffer, contentType: ContentType?) where E : Encodable {
        return (buffer: ByteBuffer(string: try encode(value)), contentType: .urlForm)
    }
}

extension URLEncodedFormDecoder: ContentDecoder {
    public func decodeContent<D>(_ type: D.Type, from buffer: ByteBuffer, contentType: ContentType?) throws -> D where D : Decodable {
        try decode(type, from: buffer.string() ?? "")
    }
}
