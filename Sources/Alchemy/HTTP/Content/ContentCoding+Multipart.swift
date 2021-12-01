import MultipartKit

extension ContentEncoder where Self == FormDataEncoder {
    public static var multipart: FormDataEncoder { FormDataEncoder() }
}

extension ContentDecoder where Self == FormDataDecoder {
    public static var multipart: FormDataDecoder { FormDataDecoder() }
}

extension FormDataEncoder: ContentEncoder {
    static var boundary: () -> String = { "AlchemyFormBoundary" + .randomAlphaNumberic(15) }
    
    public func encodeContent<E>(_ value: E) throws -> Content where E: Encodable {
        let boundary = FormDataEncoder.boundary()
        return .string(try encode(value, boundary: boundary), type: .multipart(boundary: boundary))
    }
}

extension FormDataDecoder: ContentDecoder {
    public func decodeContent<D>(_ type: D.Type, from content: Content) throws -> D where D: Decodable {
        guard let boundary = content.type?.parameters["boundary"] else {
            throw HTTPError(.notAcceptable, message: "Attempted to decode multipart/form-data but couldn't find a `boundary` in the `Content-Type` header.")
        }
        
        return try decode(type, from: content.buffer, boundary: boundary)
    }
}

extension String {
    static func randomAlphaNumberic(_ length: Int) -> String {
        String((1...length).compactMap { _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() })
    }
}
