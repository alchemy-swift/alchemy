import Foundation

extension ContentEncoder where Self == JSONEncoder {
    public static var json: JSONEncoder { JSONEncoder() }
}

extension ContentDecoder where Self == JSONDecoder {
    public static var json: JSONDecoder { JSONDecoder() }
}

extension JSONEncoder: ContentEncoder {
    public func encodeContent<E>(_ value: E) throws -> (buffer: ByteBuffer, contentType: ContentType?) where E : Encodable {
        (buffer: ByteBuffer(data: try encode(value)), contentType: .json)
    }
}

extension JSONDecoder: ContentDecoder {
    public func decodeContent<D>(_ type: D.Type, from buffer: ByteBuffer, contentType: ContentType?) throws -> D where D : Decodable {
        try decode(type, from: buffer.data() ?? Data())
    }
}
