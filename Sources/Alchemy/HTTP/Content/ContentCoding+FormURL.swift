import HummingbirdFoundation

extension ContentEncoder where Self == URLEncodedFormEncoder {
    public static var urlForm: URLEncodedFormEncoder { URLEncodedFormEncoder() }
}

extension ContentDecoder where Self == URLEncodedFormDecoder {
    public static var urlForm: URLEncodedFormDecoder { URLEncodedFormDecoder() }
}

extension URLEncodedFormEncoder: ContentEncoder {
    public func encodeContent<E>(_ value: E) throws -> Content where E: Encodable {
        Content(buffer: ByteBuffer(string: try encode(value)), type: .urlForm)
    }
}

extension URLEncodedFormDecoder: ContentDecoder {
    public func decodeContent<D>(_ type: D.Type, from content: Content) throws -> D where D: Decodable {
        try decode(type, from: content.buffer.string() ?? "")
    }
}
