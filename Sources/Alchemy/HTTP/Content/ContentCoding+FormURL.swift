import HummingbirdFoundation

extension ContentEncoder where Self == URLEncodedFormEncoder {
    public static var url: URLEncodedFormEncoder { URLEncodedFormEncoder() }
}

extension ContentDecoder where Self == URLEncodedFormDecoder {
    public static var url: URLEncodedFormDecoder { URLEncodedFormDecoder() }
}

extension URLEncodedFormEncoder: ContentEncoder {
    public func encodeContent<E>(_ value: E) throws -> Content where E: Encodable {
        .string(try encode(value), type: .urlEncoded)
    }
}

extension URLEncodedFormDecoder: ContentDecoder {
    public func decodeContent<D>(_ type: D.Type, from content: Content) throws -> D where D: Decodable {
        try decode(type, from: content.string() ?? "")
    }
}
