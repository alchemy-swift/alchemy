import Foundation

extension ContentEncoder where Self == JSONEncoder {
    public static var json: JSONEncoder { JSONEncoder() }
}

extension ContentDecoder where Self == JSONDecoder {
    public static var json: JSONDecoder { JSONDecoder() }
}

extension JSONEncoder: ContentEncoder {
    public func encodeContent<E>(_ value: E) throws -> Content where E: Encodable {
        .data(try encode(value), type: .json)
    }
}

extension JSONDecoder: ContentDecoder {
    public func decodeContent<D>(_ type: D.Type, from content: Content) throws -> D where D: Decodable {
        try decode(type, from: content.data())
    }
}
