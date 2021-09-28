import Foundation

extension Request {
    /// Get any authorization data from the request's `Authorization`
    /// header.
    ///
    /// - Returns: An `HTTPAuth` representing relevant info in the
    ///   `Authorization` header, if it exists. Currently only
    ///   supports `Basic` and `Bearer` auth.
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
            
            return .basic(
                HTTPAuth.Basic(username: username, password: password)
            )
        } else if authString.starts(with: "Bearer ") {
            authString.removeFirst(7)
            return .bearer(HTTPAuth.Bearer(token: authString))
        } else {
            return nil
        }
    }
    
    /// Gets any `Basic` authorization data from this request.
    ///
    /// - Returns: The data from the `Authorization` header, if the
    ///   authorization type is `Basic`.
    public func basicAuth() -> HTTPAuth.Basic? {
        guard let auth = self.getAuth() else {
            return nil
        }
        
        if case let .basic(authData) = auth {
            return authData
        } else {
            return nil
        }
    }
    
    /// Gets any `Bearer` authorization data from this request.
    ///
    /// - Returns: The data from the `Authorization` header, if the
    ///   authorization type is `Bearer`.
    public func bearerAuth() -> HTTPAuth.Bearer? {
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

/// A type representing any auth that may be on an HTTP request.
/// Supports `Basic` and `Bearer`.
public enum HTTPAuth: Equatable {
    /// The basic auth of an Request. Corresponds to a header that
    /// looks like
    /// `Authorization: Basic <base64-encoded-username-password>`.
    public struct Basic: Equatable {
        /// The username of this authorization. Comes before the colon
        /// in the decoded `Authorization` header value i.e.
        /// `Basic <username>:<password>`.
        public let username: String
        /// The password of this authorization. Comes before the colon
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
