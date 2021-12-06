@testable
import Alchemy
import NIOCore
import XCTest

/// A test case class that makes it easy for you to test your app. By default
/// a new instance of your application will be setup before and shutdown
/// after each test.
///
/// You may also use this class to build & send mock http requests to your app.
open class TestCase<A: Application>: XCTestCase, ClientProvider {
    /// Helper for building requests to test your application's routing.
    public final class Builder: RequestBuilder {
        /// A request made with this builder returns a `Response`.
        public typealias Res = Response
        
        /// Build using this builder.
        public var builder: Builder { self }
        /// The request being built.
        public var partialRequest: Client.Request = .init()
        private var version: HTTPVersion = .http1_1
        private var remoteAddress: SocketAddress? = nil
        
        /// Set the http version of the mock request.
        public func withHttpVersion(_ version: HTTPVersion) -> Builder {
            self.version = version
            return self
        }
        
        /// Set the remote address of the mock request.
        public func withRemoteAddress(_ address: SocketAddress) -> Builder {
            self.remoteAddress = address
            return self
        }
        
        /// Send the built request to your application's router.
        ///
        /// - Returns: The resulting response.
        public func execute() async throws -> Response {
            let request: Request = .fixture(
                remoteAddress: remoteAddress,
                version: version,
                method: partialRequest.method,
                uri: partialRequest.urlComponents.path,
                headers: partialRequest.headers,
                body: partialRequest.body)
            return await Router.default.handle(request: request)
        }
    }
    
    /// A request made with this builder returns a `Response`.
    public typealias Res = Response
    
    /// An instance of your app, reset and configured before each test.
    public var app = A()
    /// The builder to defer to when building requests.
    public var builder: Builder { Builder() }
    
    open override func setUpWithError() throws {
        try super.setUpWithError()
        app = A()
        try app.setup()
    }
    
    open override func tearDownWithError() throws {
        try super.tearDownWithError()
        try app.stop()
    }
}
