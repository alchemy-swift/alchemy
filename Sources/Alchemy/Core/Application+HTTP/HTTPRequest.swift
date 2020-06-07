import Foundation
import NIO
import NIOHTTP1

/// A simplified HTTPRequest type as you'll come across in many web frameworks
public final class HTTPRequest {
    /// The default JSONDecoder with which to decode HTTP request bodies.
    public static var defaultJSONDecoder = JSONDecoder()
    
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
    public func set<T>(_ value: T) -> Self {
        self.middlewareData[identifier(of: T.self)] = value
        return self
    }
    
    /// Gets a value associated with this request, throws if there is not one of type `T` already set.
    public func get<T>(_ type: T.Type = T.self) throws -> T {
        try self.middlewareData[identifier(of: T.self)]
            .unwrap(as: type, or: RoutingError("Couldn't find type `\(name(of: type))` on this request"))
    }
}

public enum HTTPAuth {
    case basic(HTTPBasicAuth)
    case bearer(HTTPBearerAuth)
}

extension HTTPRequest {
    /// Get auth, if there is one
    public func getAuth() -> HTTPAuth? {
        guard var authString = self.headers.first(name: "Authorization") else {
            return nil
        }
        
        if authString.starts(with: "Basic ") {
            authString.removeFirst(6)
            
            guard let base64Data = Data(base64Encoded: authString),
                let authString = String(data: base64Data, encoding: .utf8) else
            {
                // Or maybe we should throw error?
                return nil
            }
            
            let components = authString.components(separatedBy: ":")
            guard let username = components.first else {
                return nil
            }
            
            let password = components.dropFirst().joined()
            
            return .basic(HTTPBasicAuth(username: username, password: password))
        } else if authString.starts(with: "Bearer ") {
            authString.removeFirst(7)
            return .bearer(HTTPBearerAuth(token: authString))
        } else {
            return nil
        }
    }
    
    /// Get basic auth, if there is one
    public func basicAuth() -> HTTPBasicAuth? {
        guard let auth = self.getAuth() else {
            return nil
        }
        
        if case let .basic(authData) = auth {
            return authData
        } else {
            return nil
        }
    }
    
    /// Get bearer auth, if there is one
    public func bearerAuth() -> HTTPBearerAuth? {
        guard let auth = self.getAuth() else {
            return nil
        }
        
        if case let .bearer(authData) = auth {
            return authData
        } else {
            return nil
        }
    }
}

public struct HTTPBasicAuth {
    public let username: String
    public let password: String
}

public struct HTTPBearerAuth {
    public let token: String
}

struct RoutingError: Error {
    let info: String
    init(_ info: String) { self.info = info }
}
