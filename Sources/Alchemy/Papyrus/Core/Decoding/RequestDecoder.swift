/// Implement this for models you want to decode.
public protocol RequestCodable: Codable {}

/// Implement this on the server side. Won't be needed with a custom decoder.
//public protocol RequestDecoder: Decoder {
//    func getHeader(for key: String) throws -> String
//    func getQuery<T: Decodable>(for key: String) throws -> T
//    func getBody<T: Decodable>() throws -> T
//    func pathComponent(for key: String) throws -> String
//}

public extension HTTPRequest {
    func load<T: RequestCodable>(_ type: T.Type) throws -> T {
        try T(from: HTTPRequestDecoder(request: self, keyMappingStrategy: .convertToSnakeCase))
    }
}
