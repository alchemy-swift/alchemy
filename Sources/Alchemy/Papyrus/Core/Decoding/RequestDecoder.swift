/// Implement this for models you want to decode.
public protocol RequestLoadable {
    init(from decoder: RequestDecoder) throws
}

/// Implement this on the server side. Won't be needed with a custom decoder.
public protocol RequestDecoder {
    func getHeader(for key: String) throws -> String
    func getQuery<T: Decodable>(for key: String) throws -> T
    func getBody<T: Decodable>() throws -> T
    func pathComponent(for key: String) throws -> String
}

public extension RequestDecoder {
    func load<T: RequestLoadable>(_ type: T.Type) throws -> T {
        try T(from: self)
    }
}
