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
            return Content(value: parse(val: topLevel))
        } catch {
            return Content(error: .misc(error))
        }
    }
    
    private func parse(val: Any) -> Content.Value {
        if let dict = val as? [String: Any] {
            return .dictionary(dict.mapValues { parse(val: $0) })
        } else if let array = val as? [Any] {
            return .array(array.map { parse(val: $0) })
        } else if let string = val as? String {
            return .string(string)
        } else if let int = val as? Int {
            return .int(int)
        } else if let double = val as? Double {
            return .double(double)
        } else if let bool = val as? Bool {
            return .bool(bool)
        } else if (val as? NSNull) != nil {
            return .null
        } else {
            return .null
        }
    }
}
