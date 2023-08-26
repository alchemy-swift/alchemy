@testable
import Alchemy
import NIOCore
import XCTest

/// A test case class that makes it easy for you to test your app. By default
/// a new instance of your application will be setup before and shutdown
/// after each test.
///
/// You may also use this class to build & send mock http requests to your app.
open class TestCase<A: Application>: XCTestCase {
    public final class Builder: RequestBuilder {
        public var urlComponents = URLComponents()
        public var method: HTTPMethod = .GET
        public var headers: HTTPHeaders = [:]
        public var body: Bytes? = nil
        private var version: HTTPVersion = .http1_1
        private var remoteAddress: SocketAddress? = nil
        
        /// Set the http version of the mock request.
        public func withHttpVersion(_ version: HTTPVersion) -> Self {
            with { $0.version = version }
        }
        
        /// Set the remote address of the mock request.
        public func withRemoteAddress(_ address: SocketAddress) -> Self {
            with { $0.remoteAddress = address }
        }
        
        public func execute() async throws -> Response {
            await A.current.router.handle(
                request: .fixture(
                    remoteAddress: remoteAddress,
                    version: version,
                    method: method,
                    uri: urlComponents.path,
                    headers: headers,
                    body: body))
        }
    }
    
    /// An instance of your app, reset and configured before each test.
    public var app = A()
    public var Test: Builder { Builder() }
    
    open override func setUp() async throws {
        try await super.setUp()
        app = A()
        try app.setup()
    }
    
    open override func tearDown() async throws {
        try await super.tearDown()
        try app.stop()
    }
}
