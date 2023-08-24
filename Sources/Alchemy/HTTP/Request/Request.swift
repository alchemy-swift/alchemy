import Foundation
import NIO
import NIOHTTP1

/// A type that represents inbound requests to your application.
public final class Request: RequestInspector {
    /// The request body.
    public var body: ByteContent?
    /// The byte buffer of this request's body, if there is one.
    public var buffer: ByteBuffer? { body?.buffer }
    /// The stream of this request's body, if there is one.
    public var stream: ByteStream? { body?.stream }
    /// The remote address where this request came from.
    public var remoteAddress: SocketAddress?
    /// The remote address where this request came from.
    public var ip: String { remoteAddress?.ipAddress ?? "" }
    /// The event loop this request is being handled on.
    public var loop: EventLoop
    /// The HTTPMethod of the request.
    public var method: HTTPMethod
    /// The HTTPVersion of the request.
    public var version: HTTPVersion
    /// Any headers associated with the request.
    public var headers: HTTPHeaders
    /// The complete url of the request.
    public var url: URL { urlComponents.url ?? URL(fileURLWithPath: "") }
    /// The path of the request. Does not include the query string.
    public var path: String { urlComponents.path }
    /// Any query items parsed from the URL. These are not percent encoded.
    public var queryItems: [URLQueryItem]? { urlComponents.queryItems }
    /// A container for storing associated types and services.
    public let container: Container
    /// The url components of this request.
    public let urlComponents: URLComponents
    /// When the request was received by the server.
    public var createdAt: Date
    /// Parameters parsed from the path.
    public var parameters: [Parameter] {
        get { container.get(\Request.parameters) }
        set { container.set(\Request.parameters, value: newValue) }
    }

    public init(head: HTTPRequestHead, body: ByteContent?, context: RequestContext) {
        self.headers = head.headers
        self.version = head.version
        self.remoteAddress = context.remoteAddress
        self.loop = context.eventLoop
        self.method = head.method
        self.urlComponents = URLComponents(string: head.uri) ?? URLComponents()
        self.container = Container(parent: .main)
        self.createdAt = Date()
        self.parameters = []
        self.body = body
    }
    
    public func parameter<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        parameters.first(where: { $0.key == key }).map { L($0.value) } ?? nil
    }
    
    /// Returns the first parameter for the given key, if there is one.
    ///
    /// Use this to fetch any parameters from the path.
    /// ```swift
    /// app.post("/users/:user_id") { request in
    ///     let userId: Int = try request.parameter("user_id")
    ///     ...
    /// }
    /// ```
    public func parameter<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) throws -> L {
        guard let parameterString: String = parameters.first(where: { $0.key == key })?.value else {
            throw ValidationError("expected parameter \(key)")
        }
        
        guard let converted = L(parameterString) else {
            throw ValidationError("parameter \(key) was \(parameterString) which couldn't be converted to \(name(of: L.self))")
        }
        
        return converted
    }
}
