import Foundation

extension Endpoint {
    /// Gets any information that may be needed to request this
    /// `Endpoint`.
    ///
    /// - Parameter dto: An instance of `Endpoint.Request`.
    /// - Throws: any errors that may occur when parsing out data from
    ///   the `Endpoint`.
    /// - Returns: A struct containing any information needed to
    ///   request this endpoint with the provided instance of `Request`.
    public func parameters(dto: Request) throws -> RequestComponents {
        let helper = EncodingHelper(dto)
        return RequestComponents(
            method: self.method,
            headers: helper.getHeaders(),
            basePath: self.path,
            query: helper.queryString(),
            fullPath: try helper.getFullPath(self.path),
            body: try helper.getBody(),
            bodyEncoding: Request.bodyEncoding
        )
    }
}

/// Represents the components needed to make an HTTP request.
public struct RequestComponents {
    /// The method of this request.
    public let method: EndpointMethod
    
    /// Any headers that may be on this request.
    public let headers: [String: String]
    
    /// The base path of this request, without any path parameters
    /// replaced.
    public let basePath: String
    
    /// The query string of this request.
    public let query: String
    
    /// The full path of this request, including any path parameters
    /// _and_ the query string.
    public let fullPath: String
    
    /// The body of this request.
    public let body: AnyEncodable?
    
    /// Body encoding.
    public let bodyEncoding: BodyEncoding
    
    /// Creates a simple `RequestComponents` with just a url and an
    /// endpoint method.
    ///
    /// - Parameters:
    ///   - url: The url of the request.
    ///   - method: The method of the request.
    /// - Returns: The `RequestComponents` representing a request with
    ///   the given `url` and `method`.
    public static func just(url: String, method: EndpointMethod) -> RequestComponents {
        RequestComponents(
            method: method,
            headers: [:],
            basePath: url,
            query: "",
            fullPath: url,
            body: nil,
            bodyEncoding: .json
        )
    }
    
    /// Creates a string representing any URL parameters this request
    /// should have. This returns nil if `self.body` is nil or it's
    /// content type is not `.urlEncoded`.
    ///
    /// - Throws: Any error encountered while encoding the
    ///   `self.body.content` to a URL `String`.
    /// - Returns: The url parameters string of this request, or nil
    ///   if it has none.
    public func urlParams() throws -> String? {
        guard let body = self.body, self.bodyEncoding == .urlEncoded else {
            return nil
        }
        
        let encoder = URLFormEncoder()
        return try encoder.encode(body)
    }
}

/// Private helper type for pulling out the relevant request
/// components from an `EndpointRequest`.
private struct EncodingHelper {
    /// Erased storage of any `@Boyd`s on the request.
    private var bodies: [String: AnyBody] = [:]
    
    /// Erased storage of any `@Header`s on the request.
    private var headers: [String: Header] = [:]
    
    /// Erased storage of any `@Query`s on the request.
    private var queries: [String: AnyQuery] = [:]
    
    /// Erased storage of any `@Path`s on the request.
    private var paths: [String: Path] = [:]
    
    /// Initialize from a generic `EndpointRequest`.
    ///
    /// - Warning: Uses `Mirror` so it will have poor efficiency at
    ///   high volume. Ideally, this will be replaced by a custom
    ///   `Encoder`.
    ///
    /// - Parameter value: The value to load request data from.
    fileprivate init<T: EndpointRequest>(_ value: T) {
        Mirror(reflecting: value)
            .children
            .forEach { child in
                guard let label = child.label else {
                    return print("No label on a child")
                }

                let sanitizedLabel = String(label.dropFirst())
                if let query = child.value as? AnyQuery {
                    self.queries[sanitizedLabel] = query
                } else if let body = child.value as? AnyBody {
                    self.bodies[sanitizedLabel] = body
                } else if let header = child.value as? Header {
                    self.headers[sanitizedLabel] = header
                } else if let path = child.value as? Path {
                    self.paths[sanitizedLabel] = path
                }
            }
    }
    
    /// Generates the full path of this request, including any path
    /// parameters, queries, or URL encoded values.
    ///
    /// - Parameter basePath: The base path of the request.
    /// - Throws: Any error encountered while encoding to the URL.
    /// - Returns: The full path of this request.
    func getFullPath(_ basePath: String) throws -> String {
        try self.replacedPath(basePath) + self.queryString()
    }
    
    /// Generates and returns the query string of this request.
    ///
    /// - Returns: A `String` with the queries of this request or an
    ///   empty string if this request has no queries.
    func queryString() -> String {
        self.queries.isEmpty ? "" : "?" + self.queries
            .sorted { $0.key < $1.key }
            .reduce(into: []) { list, query in
                list += String.queryComponents(fromKey: query.key, value: query.value.value)
            }
            .map { (key: String, value: String) in
                "\(key)" + (value.isEmpty ? "" : "=\(value)")
            }
            .joined(separator: "&")
    }
    
    /// Returns a tuple representing the content and content type of
    /// this request's body.
    ///
    /// - Throws: An error if there is more than one `@Body` on the
    ///   `EndpointRequest` used to generate this helper.
    /// - Returns: A type representing the content and content type
    ///   of this request's body.
    func getBody() throws -> AnyEncodable? {
        guard self.bodies.count <= 1 else {
            throw PapyrusError("Only one `@Body` attribute is allowed per request. This will likely"
                                + " be a `Codable` type with all the body's fields on it.")
        }
        
        return self.bodies.first.map { $0.value.content }
    }
    
    /// Generates the headers of this request.
    ///
    /// - Returns: A `[String: String]` representing the headers of
    ///   this request.
    func getHeaders() -> [String: String] {
        self.headers.reduce(into: [:]) { $0[$1.key] = $1.value.wrappedValue }
    }
    
    /// Given a `basePath`, returns a string representing the base
    /// path with all path component placeholders replaced by this
    /// request's path components.
    ///
    /// - Parameter basePath: The base path that contains path
    ///   component placeholders (prefaced by `:`).
    /// - Throws: A `PapyrusError` if the request has a path component
    ///   that doesn't have a matching placeholder in the `basePath`.
    /// - Returns: The `basePath` with all path component placeholders
    ///   replaced with their respective values.
    private func replacedPath(_ basePath: String) throws -> String {
        try self.paths.reduce(into: basePath) { basePath, component in
            guard basePath.contains(":\(component.key)") else {
                throw PapyrusError("Tried to encode path component '\(component.key)' but didn't find any instance of ':\(component.key)' in the path.")
            }

            basePath = basePath
                .replacingOccurrences(of: ":\(component.key)", with: component.value.wrappedValue)
        }
    }
}
