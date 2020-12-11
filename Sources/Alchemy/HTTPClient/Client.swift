import AsyncHTTPClient
import Fusion
import NIO

/// Global singleton accessor & convenient typealias for a default client.
public typealias Client = HTTPClientDefault
public struct HTTPClientDefault {
    public static var `default`: HTTPClient {
        get {
            return _default
        }
        set {
            try? HTTPClientDefault._default.syncShutdown()
            HTTPClientDefault._default = newValue
        }
    }
    
    private static var _default: HTTPClient = {
        let multi = try! Container.global.resolve(MultiThreadedEventLoopGroup.self)
        return HTTPClient(eventLoopGroupProvider: .shared(multi))
    }()
}
