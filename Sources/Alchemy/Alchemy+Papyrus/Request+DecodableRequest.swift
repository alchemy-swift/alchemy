import Papyrus

extension Request: DecodableRequest {
    public func header(_ key: String) -> String? {
        headers.first(name: key)
    }
    
    public func query(_ key: String) -> String? {
        queryItems.filter ({ $0.name == key }).first?.value
    }
    
    public func parameter(_ key: String) -> String? {
        parameter(key)?.value
    }
    
    public func decodeContent<T>(type: Papyrus.ContentType) throws -> T where T : Decodable {
        switch type {
        case .json:
            return try decodeBodyJSON(as: T.self)
        case .urlEncoded:
            throw HTTPError(.unsupportedMediaType)
        }
    }
}
