import Foundation
import NIO
import NIOHTTP1

/// A simplified HTTPRequest type as you'll come across in many web frameworks
public final class HTTPRequest {
    /// The EventLoop is stored in the HTTP request so that promises can be created
    public let eventLoop: EventLoop
    
    /// The head contains all request "metadata" like the URI and request method
    ///
    /// The headers are also found in the head, and they are often used to describe the body as well
    public let head: HTTPRequestHead
    
    /// The url components of this request.
    public let components: URLComponents?
    
    /// The any parameters inside the path.
    public var pathParameters: [PathParameter] = []
    
    /// The bodyBuffer is internal because the HTTPBody API is exposed for simpler access
    var bodyBuffer: ByteBuffer?
    
    /// Any information set by a middleware.
    var middlewareData: [ObjectIdentifier: Any] = [:]
    
    /// This initializer is necessary because the `bodyBuffer` is a private property
    init(eventLoop: EventLoop, head: HTTPRequestHead, bodyBuffer: ByteBuffer?) {
        self.eventLoop = eventLoop
        self.head = head
        self.bodyBuffer = bodyBuffer
        self.components = URLComponents(string: head.uri)
    }
}

extension HTTPRequest {
    /// The HTTPMethod of the request.
    public var method: HTTPMethod {
        self.head.method
    }
    
    /// The path of the request. Does not include the query string.
    public var path: String {
        self.components?.path ?? ""
    }
    
    /// Any headers associated with the request.
    public var headers: HTTPHeaders {
        self.head.headers
    }
    
    /// Any query items parsed from the URL. These are not percent encoded.
    public var queryItems: [URLQueryItem] {
        self.components?.queryItems ?? []
    }
    
    /// Returns the first `PathParameter` for the given key, if there is one.
    public func pathParameter(named key: String) -> PathParameter? {
        self.pathParameters.first(where: { $0.parameter == "key" })
    }
    
    /// The body is a wrapper used to provide simpler access to body data like JSON.
    public var body: HTTPBody? {
        guard let bodyBuffer = bodyBuffer else {
            return nil
        }
        
        return HTTPBody(buffer: bodyBuffer)
    }
    
    /// Sets a value associated with this request. Useful for setting objects with middleware.
    public func set<T>(_ value: T) {
        self.middlewareData[identifier(of: T.self)] = value
    }
    
    /// Gets a value associated with this request, throws if there is not one of type `T` already set.
    public func get<T>(_ type: T.Type = T.self) throws -> T {
        try self.middlewareData[identifier(of: T.self)]
            .unwrap(as: type, or: RoutingError("Couldn't find type `\(name(of: type))` on this request"))
    }
}

struct RoutingError: Error {
    let info: String
    init(_ info: String) { self.info = info }
}
