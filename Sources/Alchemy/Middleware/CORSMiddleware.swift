/// The MIT License (MIT)
///
/// Copyright (c) 2020 Qutheory, LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///
/// Courtesy of https://github.com/vapor/vapor

/// Middleware that adds support for CORS settings in request
/// responses. For configuration of this middleware please
/// use the `CORSMiddleware.Configuration` object.
///
/// - Note: Make sure this middleware is inserted before all your
///   error/abort middlewares, so that even the failed request
///   responses contain proper CORS information.
public final class CORSMiddleware: Middleware {
    /// Option for the allow origin header in responses for CORS
    /// requests.
    ///
    /// - none: Disallows any origin.
    /// - originBased: Uses value of the origin header in the request.
    /// - all: Uses wildcard to allow any origin.
    /// - any: A list of allowable origins.
    /// - custom: Uses custom string provided as an associated value.
    public enum AllowOriginSetting {
        /// Disallow any origin.
        case none

        /// Uses value of the origin header in the request.
        case originBased

        /// Uses wildcard to allow any origin.
        case all
        
        /// A list of allowable origins.
        case any([String])

        /// Uses custom string provided as an associated value.
        case custom(String)

        /// Creates the header string depending on the case of self.
        ///
        /// - Parameter request: Request for which the allow origin
        ///   header should be created.
        /// - Returns: Header string to be used in response for
        ///   allowed origin.
        public func header(forRequest req: Request) -> String {
            switch self {
            case .none: return ""
            case .originBased: return req.headers["Origin"].first ?? ""
            case .all: return "*"
            case .any(let origins):
                guard let origin = req.headers["Origin"].first else {
                    return ""
                }
                return origins.contains(origin) ? origin : ""
            case .custom(let string):
                return string
            }
        }
    }


    /// Configuration used for populating headers in response for CORS
    /// requests.
    public struct Configuration {
        /// Default CORS configuration.
        ///
        /// - Allow Origin: Based on request's `Origin` value.
        /// - Allow Methods: `GET`, `POST`, `PUT`, `OPTIONS`,
        ///   `DELETE`, `PATCH`
        /// - Allow Headers: `Accept`, `Authorization`,
        ///   `Content-Type`, `Origin`, `X-Requested-With`
        public static func `default`() -> Configuration {
            return .init(
                allowedOrigin: .originBased,
                allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
                allowedHeaders: ["Accept", "Authorization", "Content-Type", "Origin", "X-Requested-With"]
            )
        }

        /// Setting that controls which origin values are allowed.
        public let allowedOrigin: AllowOriginSetting

        /// Header string containing methods that are allowed for a
        /// CORS request response.
        public let allowedMethods: String

        /// Header string containing headers that are allowed in a
        /// response for CORS request.
        public let allowedHeaders: String

        /// If set to yes, cookies and other credentials will be sent
        /// in the response for CORS request.
        public let allowCredentials: Bool

        /// Optionally sets expiration of the cached pre-flight
        /// request. Value is in seconds.
        public let cacheExpiration: Int?

        /// Headers exposed in the response of pre-flight request.
        public let exposedHeaders: String?

        /// Instantiate a CORSConfiguration struct that can be used to
        /// create a `CORSConfiguration` middleware for adding support
        /// for CORS in your responses.
        ///
        /// - parameters:
        ///   - allowedOrigin: Setting that controls which origin
        ///     values are allowed.
        ///   - allowedMethods: Methods that are allowed for a CORS
        ///     request response.
        ///   - allowedHeaders: Headers that are allowed in a response
        ///     for CORS request.
        ///   - allowCredentials: If cookies and other credentials
        ///     will be sent in the response.
        ///   - cacheExpiration: Optionally sets expiration of the
        ///     cached pre-flight request in seconds.
        ///   - exposedHeaders: Headers exposed in the response of
        ///     pre-flight request.
        public init(
            allowedOrigin: AllowOriginSetting,
            allowedMethods: [HTTPMethod],
            allowedHeaders: [String],
            allowCredentials: Bool = false,
            cacheExpiration: Int? = 600,
            exposedHeaders: [String]? = nil
        ) {
            self.allowedOrigin = allowedOrigin
            self.allowedMethods = allowedMethods.map({ "\($0)" }).joined(separator: ", ")
            self.allowedHeaders = allowedHeaders.map({ String(describing: $0) }).joined(separator: ", ")
            self.allowCredentials = allowCredentials
            self.cacheExpiration = cacheExpiration
            self.exposedHeaders = exposedHeaders?.map({ String(describing: $0) }).joined(separator: ", ")
        }
    }

    /// Configuration used for populating headers in response for CORS
    /// requests.
    public let configuration: Configuration
    
    /// Creates a CORS middleware with the specified configuration.
    ///
    /// - Parameter configuration: Configuration used for populating
    ///   headers in response for CORS requests.
    public init(configuration: Configuration = .default()) {
        self.configuration = configuration
    }

    // MARK: Middleware
    
    public func intercept(_ request: Request, next: Next) async throws -> Response {
        // Check if it's valid CORS request
        guard request.headers["Origin"].first != nil else {
            return try await next(request)
        }
        
        // Determine if the request is pre-flight. If it is, create
        // empty response otherwise get response from the responder
        // chain.
        let response = request.isPreflight ? Response(status: .ok, body: nil) : try await next(request)
        
        // Modify response headers based on CORS settings
        response.headers.replaceOrAdd(
            name: "Access-Control-Allow-Origin",
            value: self.configuration.allowedOrigin.header(forRequest: request)
        )
        response.headers.replaceOrAdd(
            name: "Access-Control-Allow-Headers",
            value: self.configuration.allowedHeaders
        )
        response.headers.replaceOrAdd(
            name: "Access-Control-Allow-Methods",
            value: self.configuration.allowedMethods
        )
        
        if let exposedHeaders = self.configuration.exposedHeaders {
            response.headers.replaceOrAdd(name: "Access-Control-Expose-Headers", value: exposedHeaders)
        }
        
        if let cacheExpiration = self.configuration.cacheExpiration {
            response.headers.replaceOrAdd(name: "Access-Control-Max-Age", value: String(cacheExpiration))
        }
        
        if self.configuration.allowCredentials {
            response.headers.replaceOrAdd(
                name: "Access-Control-Allow-Credentials",
                value: "true"
            )
        }
        
        return response
    }
}

private extension Request {
    /// Returns `true` if the request is a pre-flight CORS request.
    var isPreflight: Bool {
        return self.method.rawValue == "OPTIONS"
            && self.headers["Access-Control-Request-Method"].first != nil
    }
}
