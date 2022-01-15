import Foundation
import NIOHTTP1

public protocol RequestInspector: ContentInspector {
    var method: HTTPMethod { get }
    var urlComponents: URLComponents { get }
}

extension RequestInspector {
    public func query(_ key: String) -> String? {
        urlComponents.queryItems?.first(where: { $0.name == key })?.value
    }
    
    public func query<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        query(key).map { L($0) } ?? nil
    }
}
