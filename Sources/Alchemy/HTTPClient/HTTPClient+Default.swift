import AsyncHTTPClient
import Fusion
import NIO

/// A global singleton accessor & convenient typealias for a default client.
///
/// - Note: see
/// [async-http-client](https://github.com/swift-server/async-http-client)
///
/// Usage:
/// ```
/// Client.default
///     .get(url: "https://swift.org")
///     .whenComplete { result in
///         switch result {
///             case .failure(let error):
///                 ...
///             case .success(let response):
///                 ...
///         }
///     }
/// ```
public typealias Client = HTTPClientDefault

/// Struct for wrapping a default `HTTPClient` for convenient use. See `Client`.
public struct HTTPClientDefault {
    /// The default HTTPClient for easy access.
    public static var `default`: HTTPClient {
        get {
            return _default
        }
        set {
            try? HTTPClientDefault._default.syncShutdown()
            HTTPClientDefault._default = newValue
        }
    }
    
    /// The under the hood default `HTTPClient`, separate because we need the
    /// `syncShutdown` in the setter above.
    private static var _default: HTTPClient = {
        let multi = try! Container.global.resolve(MultiThreadedEventLoopGroup.self)
        return HTTPClient(eventLoopGroupProvider: .shared(multi))
    }()
}
