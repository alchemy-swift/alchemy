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
        try decode(type, from: buffer.data)
    }
    
    public func content(from buffer: ByteBuffer, contentType: ContentType?) -> Content {
        do {
            let topLevel = try JSONSerialization.jsonObject(with: buffer, options: .fragmentsAllowed)
            return Content(root: parse(val: topLevel))
        } catch {
            return Content(error: error)
        }
    }
    
    private func parse(val: Any) -> Content.Node {
        if let dict = val as? [String: Any] {
            return .dict(dict.mapValues { parse(val: $0) })
        } else if let array = val as? [Any] {
            return .array(array.map { parse(val: $0) })
        } else if (val as? NSNull) != nil {
            return .null
        } else {
            return .value(JSONValue(value: val))
        }
    }
    
    private struct JSONValue: ContentValue {
        let value: Any
        
        var string: String? { value as? String }
        var bool: Bool? { value as? Bool }
        var int: Int? { value as? Int }
        var double: Double? { value as? Double }
        var file: File? { nil }
    }
}
