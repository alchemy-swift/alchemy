import Foundation

extension HTTPRequest: RequestDecoder {
    public func getHeader(for key: String) throws -> String {
        try self.headers.first(name: key)
            .unwrap(or: SwiftAPIError(message: "Expected `\(key)` in the request headers."))
    }
    
    public func getQuery<T: Decodable>(for key: String) throws -> T {
        do {
            throw SwiftAPIError(message: "not available yet")
        } catch {
            throw SwiftAPIError(message: "Encountered an error getting `\(key)` from the request query. \(error).")
        }
    }
    
    public func pathComponent(for key: String) throws -> String {
        try self.pathParameters.first(where: { $0.parameter == key })
            .unwrap(or: SwiftAPIError(message: "Expected `\(key)` in the request path components."))
            .stringValue
    }
    
    public func getBody<T>() throws -> T where T : Decodable {
        do {
            return try self.body
                .unwrap(or: HTTPError(.internalServerError))
                .decodeJSON(as: T.self)
        } catch {
            throw SwiftAPIError(message: "Encountered an error decoding the body to type `\(T.self)`: \(error)")
        }
    }
}
