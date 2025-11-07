import Foundation
import NIOCore

/// A type that represents inbound requests to your application.
public final class Request: RequestInspector {
    /// The default decoder for decoding incoming requests.
    public static var defaultDecoder: HTTPDecoder = .json

    /// Represents a dynamic parameter inside the path. Parameter placeholders
    /// should be prefaced with a colon (`:`) in the route string. Something
    /// like `:user_id` in the path `/v1/users/:user_id`.
    public struct Parameter: Equatable {
        /// The escaped parameter that was matched, _without_ the colon.
        /// Something like `user_id` if `:user_id` were in the path.
        public let key: String
        /// The actual string value of the parameter.
        public let value: String

        /// Returns the `String` value of this parameter.
        public func string() -> String {
            value
        }

        /// Decodes an `Int` from this parameter's value or throws if the string
        /// can't be converted to an `Int`.
        public func int() throws -> Int {
            guard let int = Int(value) else {
                throw ValidationError("Unable to decode Int for '\(key)'. Value was '\(value)'.")
            }

            return int
        }

        /// Decodes a `UUID` from this parameter's value or throws if the string
        /// is an invalid `UUID`.
        public func uuid() throws -> UUID {
            guard let uuid = UUID(uuidString: value) else {
                throw ValidationError("Unable to decode UUID for '\(key)'. Value was '\(value)'.")
            }

            return uuid
        }
    }

    /// A type representing any auth that may be on an HTTP request. Supports
    /// `Basic` and `Bearer`.
    public enum Auth: Equatable {
        /// The basic auth of an Request. Corresponds to a header that
        /// looks like
        /// `Authorization: Basic <base64-encoded-username-password>`.
        public struct Basic: Equatable {
            /// The username of this authorization. Comes before the colon
            /// in the decoded `Authorization` header value i.e.
            /// `Basic <username>:<password>`.
            public let username: String
            /// The password of this authorization. Comes after the colon
            /// in the decoded `Authorization` header value i.e.
            /// `Basic <username>:<password>`.
            public let password: String
        }

        /// The bearer auth of an Request. Corresponds to a header that
        /// looks like `Authorization: Bearer <token>`.
        public struct Bearer: Equatable {
            /// The token in the `Authorization` header value.
            /// i.e. `Bearer <token>`.
            public let token: String
        }

        /// The `Authorization` of this request is `Basic`.
        case basic(Basic)
        /// The `Authorization` of this request is `Bearer`.
        case bearer(Bearer)
    }

    // MARK: Stored Properties

    /// The HTTPRequest.Method of the request.
    public var method: HTTPRequest.Method
    /// The URI of the request.
    public var uri: String
    /// Any headers associated with the request.
    public var headers: HTTPFields
    /// The request body.
    public var body: Bytes?
    /// The remote address where this request came from.
    public var remoteAddress: SocketAddress?
    /// The local address where this request is sent too from.
    public var localAddress: SocketAddress?
    /// A container for storing associated types and services.
    public let container: Container

    // MARK: Computed Properties

    /// The remote address where this request came from.
    public var ip: String { remoteAddress?.ipAddress ?? "" }
    /// The complete url of the request.
    public var url: URL { urlComponents.url ?? URL(fileURLWithPath: "") }
    /// The path of the request. Does not include the query string.
    public var path: String { urlComponents.path }
    /// Any query items parsed from the URL. These are not percent encoded.
    public var queryItems: [URLQueryItem]? { urlComponents.queryItems }
    /// Parameters parsed from the path.
    public var parameters: [Parameter] {
        get { Container.requestParameters ?? [] }
        set { Container.requestParameters = newValue }
    }
    
    /// The url components of this request.
    public var urlComponents: URLComponents {
        get {
            guard let components = Container.urlComponents else {
                let components = URLComponents(string: uri) ?? URLComponents()
                Container.urlComponents = components
                return components
            }

            return components
        }
        set { Container.urlComponents = newValue }
    }

    public init(
        method: HTTPRequest.Method,
        uri: String,
        headers: HTTPFields = [:],
        body: Bytes? = nil,
        localAddress: SocketAddress? = nil,
        remoteAddress: SocketAddress? = nil,
        container: Container = Container()
    ) {
        self.method = method
        self.uri = uri
        self.headers = headers
        self.body = body
        self.localAddress = localAddress
        self.remoteAddress = remoteAddress
        self.container = Container()
    }

    /// Collects the body of this request into a single `ByteBuffer`. If it is
    /// a stream, this function will return when the stream is finished. If
    /// the body is already a single `ByteBuffer`, this function will
    /// return immediately.
    @discardableResult
    public func collect() async throws -> Request {
        if let body {
            self.body = .buffer(try await body.collect())
        }

        return self
    }

    // MARK: Parameters

    /// Returns the first parameter for the given key, if there is one.
    public func parameter<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) -> L? {
        parameters.first(where: { $0.key == key }).map { L($0.value) } ?? nil
    }
    
    /// Returns the first parameter for `key` or throws an error if one doesn't
    /// exist.
    ///
    /// Use this to fetch any parameters from the path.
    /// ```swift
    /// app.post("/users/:user_id") { request in
    ///     let userId: Int = try request.requireParameter("user_id")
    ///     ...
    /// }
    /// ```
    public func requireParameter<L: LosslessStringConvertible>(_ key: String, as: L.Type = L.self) throws -> L {
        guard let parameterString: String = parameters.first(where: { $0.key == key })?.value else {
            throw ValidationError("Missing path parameter \(key).")
        }
        
        guard let converted = L(parameterString) else {
            throw ValidationError("Invalid path parameter \(key). Unable to convert \(parameterString) to \(L.self).")
        }
        
        return converted
    }

    // MARK: Auth

    /// Get any authorization data from the request's `Authorization` header.
    ///
    /// - Returns: An `HTTPAuth` representing relevant info in the
    ///   `Authorization` header, if it exists. Currently only
    ///   supports `Basic` and `Bearer` auth.
    public func getAuth() -> Auth? {
        guard var authString = headers[values: .authorization].first else {
            return nil
        }

        if authString.starts(with: "Basic ") {
            authString.removeFirst(6)

            guard
                let base64Data = Data(base64Encoded: authString),
                let authString = String(data: base64Data, encoding: .utf8)
            else {
                return nil
            }

            guard !authString.isEmpty else {
                return nil
            }

            let components = authString.components(separatedBy: ":")
            let username = components[0]
            let password = components.dropFirst().joined()
            return .basic(Auth.Basic(username: username, password: password))
        } else if authString.starts(with: "Bearer ") {
            authString.removeFirst(7)
            return .bearer(Auth.Bearer(token: authString))
        }

        return nil
    }

    /// Gets any `Basic` authorization data from this request.
    ///
    /// - Returns: The data from the `Authorization` header, if the
    ///   authorization type is `Basic`.
    public func basicAuth() -> Auth.Basic? {
        guard let auth = self.getAuth() else {
            return nil
        }

        if case let .basic(authData) = auth {
            return authData
        }

        return nil
    }

    /// Gets any `Bearer` authorization data from this request.
    ///
    /// - Returns: The data from the `Authorization` header, if the
    ///   authorization type is `Bearer`.
    public func bearerAuth() -> Auth.Bearer? {
        guard let auth = getAuth() else {
            return nil
        }

        if case let .bearer(authData) = auth {
            return authData
        }

        return nil
    }

    // MARK: Associated Values

    /// Sets a value associated with this request. Useful for setting
    /// objects with middleware.
    ///
    /// Usage:
    ///
    ///     struct ExampleMiddleware: Middleware {
    ///         func handle(_ request: Request, next: Next) async throws -> Response {
    ///             let someData: SomeData = ...
    ///             return try await next(request.set(someData))
    ///         }
    ///     }
    ///
    ///     app
    ///         .use(ExampleMiddleware())
    ///         .on(.GET, at: "/example") { request in
    ///             let theData = try request.get(SomeData.self)
    ///         }
    ///
    /// - Parameter value: The value to set.
    /// - Returns: This reqeust, with the new value set internally for access
    ///   with `get(Value.self)`.
    @discardableResult
    public func set<T>(_ value: T) -> Self {
        container.set(value)
        return self
    }

    /// Gets a value associated with this request, throws if there is not a
    /// value of type `T` already set.
    public func get<T>(_ type: T.Type = T.self) throws -> T {
        guard let value = container.get(T.self) else {
            throw RequestError("Couldn't find type `\(name(of: T.self))` on this request")
        }

        return value
    }
}

struct RequestError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}

fileprivate extension Container {
    @Service(.singleton) var requestParameters: [Request.Parameter]? = nil
    @Service(.singleton) var urlComponents: URLComponents? = nil
}
