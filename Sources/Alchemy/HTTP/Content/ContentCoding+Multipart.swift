import MultipartKit

extension ContentEncoder where Self == FormDataEncoder {
    public static var multipart: FormDataEncoder { FormDataEncoder() }
}

extension ContentDecoder where Self == FormDataDecoder {
    public static var multipart: FormDataDecoder { FormDataDecoder() }
}

extension FormDataEncoder: ContentEncoder {
    static var boundary: () -> String = { "AlchemyFormBoundary" + .randomAlphaNumberic(15) }
    
    public func encodeContent<E>(_ value: E) throws -> (buffer: ByteBuffer, contentType: ContentType?) where E : Encodable {
        let boundary = FormDataEncoder.boundary()
        return (buffer: ByteBuffer(string: try encode(value, boundary: boundary)), contentType: .multipart(boundary: boundary))
    }
}

extension FormDataDecoder: ContentDecoder {
    public func decodeContent<D>(_ type: D.Type, from buffer: ByteBuffer, contentType: ContentType?) throws -> D where D : Decodable {
        guard let boundary = contentType?.parameters["boundary"] else {
            throw HTTPError(.notAcceptable, message: "Attempted to decode multipart/form-data but couldn't find a `boundary` in the `Content-Type` header.")
        }
        
        return try decode(type, from: buffer, boundary: boundary)
    }
    
    public func content(from buffer: ByteBuffer, contentType: ContentType?) -> Content {
        guard contentType == .multipart else {
            return Content(error: ContentError.unknownContentType(contentType))
        }
        
        guard let boundary = contentType?.parameters["boundary"] else {
            return Content(error: ContentError.unknownContentType(contentType))
        }
        
        let parser = MultipartParser(boundary: boundary)
        var parts: [MultipartPart] = []
        var headers: HTTPHeaders = .init()
        var body: ByteBuffer = ByteBuffer()

        parser.onHeader = { headers.replaceOrAdd(name: $0, value: $1) }
        parser.onBody = { body.writeBuffer(&$0) }
        parser.onPartComplete = {
            parts.append(MultipartPart(headers: headers, body: body))
            headers = [:]
            body = ByteBuffer()
        }
        
        do {
            try parser.execute(buffer)
            let dict = Dictionary(uniqueKeysWithValues: parts.compactMap { part in part.name.map { ($0, part) } })
            return Content(root: .dict(dict.mapValues { .value($0) }))
        } catch {
            return Content(error: error)
        }
    }
}

extension MultipartPart: ContentValue {
    public var string: String? { body.string }
    public var int: Int? { Int(body.string) }
    public var bool: Bool? { Bool(body.string) }
    public var double: Double? { Double(body.string) }
    
    public var file: File? {
        guard let disposition = headers.contentDisposition, let filename = disposition.filename else { return nil }
        return File(name: filename, source: .http(clientContentType: headers.contentType), content: .buffer(body), size: body.writerIndex)
    }
}

extension String {
    static func randomAlphaNumberic(_ length: Int) -> String {
        String((1...length).compactMap { _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() })
    }
}
