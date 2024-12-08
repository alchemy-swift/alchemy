import Foundation

public protocol RequestInspector: HTTPInspector {
    var method: HTTPRequest.Method { get }
    var urlComponents: URLComponents { get }
}

extension RequestInspector {
    public func query(_ key: String) -> String? {
        urlComponents.queryItems?.first(where: { $0.name == key })?.value
    }
    
    public func query<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        query(key).map { L($0) } ?? nil
    }

    public func requireQuery<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) throws -> L {
        guard let string = query(key) else {
            throw ValidationError("Missing query \(key).")
        }

        guard let value = L(string) else {
            throw ValidationError("Invalid query \(key). Unable to convert \(string) to \(L.self).")
        }

        return value
    }
}
