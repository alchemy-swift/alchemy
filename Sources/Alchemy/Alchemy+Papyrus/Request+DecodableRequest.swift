import Papyrus
import Foundation

extension Request: DecodableRequest {
    public func header(_ key: String) -> String? {
        headers.first(name: key)
    }
    
    public func query(_ key: String) -> String? {
        queryItems?.filter ({ $0.name == key }).first?.value
    }
    
    public func parameter(_ key: String) -> String? {
        parameters.first(where: { $0.key == key })?.value
    }
    
    public func decodeContent<T>(type: Papyrus.ContentEncoding) throws -> T where T : Decodable {
        switch type {
        case .json:
            return try decode(T.self, with: JSONDecoder())
        case .url:
            throw HTTPError(.unsupportedMediaType)
        }
    }
}
