import HummingbirdFoundation

extension HTTPEncoder where Self == URLEncodedFormEncoder {
    public static var urlForm: URLEncodedFormEncoder { URLEncodedFormEncoder() }
}

extension HTTPDecoder where Self == URLEncodedFormDecoder {
    public static var urlForm: URLEncodedFormDecoder { URLEncodedFormDecoder() }
}

extension URLEncodedFormEncoder: HTTPEncoder {
    public func encodeBody<E: Encodable>(_ value: E) throws -> (buffer: ByteBuffer, contentType: ContentType?) {
        return (buffer: ByteBuffer(string: try encode(value)), contentType: .urlForm)
    }
}

extension URLEncodedFormDecoder: HTTPDecoder {
    public func decodeBody<D: Decodable>(_ type: D.Type, from buffer: ByteBuffer, contentType: ContentType?) throws -> D {
        try decode(type, from: buffer.string)
    }
    
    public func content(from buffer: ByteBuffer, contentType: ContentType?) -> Content {
        do {
            let topLevel = try decode(URLEncodedNode.self, from: buffer.string)
            return Content(value: parse(value: topLevel))
        } catch {
            return Content(error: .misc(error))
        }
    }
    
    private func parse(value: URLEncodedNode) -> Content.Value {
        switch value {
        case .dict(let dict):
            return .dictionary(dict.mapValues { parse(value: $0) })
        case .array(let array):
            return .array(array.map { parse(value: $0) })
        case .value(let string):
            return .string(string)
        }
    }
}

enum URLEncodedNode: Decodable {
    case dict([String: URLEncodedNode])
    case array([URLEncodedNode])
    case value(String)
    
    init(from decoder: Decoder) throws {
        if let array = try? [URLEncodedNode](from: decoder) {
            self = .array(array)
        } else if let dict = try? [String: URLEncodedNode](from: decoder) {
            self = .dict(dict)
        } else {
            self = .value(try String(from: decoder))
        }
    }
}
