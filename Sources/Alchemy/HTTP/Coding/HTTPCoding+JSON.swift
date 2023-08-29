import Foundation

extension HTTPEncoder where Self == JSONEncoder {
    public static var json: JSONEncoder { JSONEncoder() }
}

extension HTTPDecoder where Self == JSONDecoder {
    public static var json: JSONDecoder { JSONDecoder() }
}

extension JSONEncoder: HTTPEncoder {
    public func encodeBody<E: Encodable>(_ value: E) throws -> (buffer: ByteBuffer, contentType: ContentType?) {
        (buffer: ByteBuffer(data: try encode(value)), contentType: .json)
    }
}

extension JSONDecoder: HTTPDecoder {
    public func decodeBody<D: Decodable>(_ type: D.Type, from buffer: ByteBuffer, contentType: ContentType?) throws -> D {
        try decode(type, from: buffer.data)
    }
    
    public func content(from buffer: ByteBuffer, contentType: ContentType?) -> Content {
        do {
            let topLevel = try JSONSerialization.jsonObject(with: buffer, options: .fragmentsAllowed)
            return Content(node: parse(val: topLevel))
        } catch {
            return Content(error: error)
        }
    }
    
    private func parse(val: Any) -> Content.State.Node {
        if let dict = val as? [String: Any] {
            return .dictionary(dict.mapValues { parse(val: $0) })
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
