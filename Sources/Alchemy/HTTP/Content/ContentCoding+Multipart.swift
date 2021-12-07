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
}

extension String {
    static func randomAlphaNumberic(_ length: Int) -> String {
        String((1...length).compactMap { _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() })
    }
}
