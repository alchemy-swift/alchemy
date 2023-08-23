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
        try decode(type, from: buffer.string)
    }
    
    public func content(from buffer: ByteBuffer, contentType: ContentType?) -> Content {
        do {
            let topLevel = try decode(URLEncodedNode.self, from: buffer.string)
            return Content(root: parse(node: topLevel))
        } catch {
            return Content(error: error)
        }
    }
    
    private func parse(node: URLEncodedNode) -> Content.Node {
        switch node {
        case .dict(let dict):
            return .dict(dict.mapValues { parse(node: $0) })
        case .array(let array):
            return .array(array.map { parse(node: $0) })
        case .value(let string):
            return .value(URLValue(value: string))
        }
    }
    
    private struct URLValue: ContentValue {
        let value: String
        
        var string: String? { value }
        var bool: Bool? { Bool(value) }
        var int: Int? { Int(value) }
        var double: Double? { Double(value) }
        var file: File? { nil }
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

extension URLEncodedNode {
    
}
