@testable
import Alchemy
import XCTest

/// A test case class that makes it easy for you to test your app. By default
/// a new instance of your application will be setup before and shutdown
/// after each test.
///
/// You may also use this class to build & send mock http requests to your app.
open class TestCase<A: Application>: XCTestCase {
    public final class Builder: RequestBuilder {
        public var urlComponents = URLComponents()
        public var method: HTTPRequest.Method = .get
        public var headers: HTTPFields = [:]
        public var body: Bytes? = nil
        private var remoteAddress: SocketAddress? = nil
        private var app: A

        fileprivate init(app: A) {
            self.app = app
        }

        /// Set the remote address of the mock request.
        public func withRemoteAddress(_ address: SocketAddress) -> Self {
            with { $0.remoteAddress = address }
        }
        
        public func execute() async -> Response {
            await app.handler.handle(
                request: .fake(
                    method: method, 
                    uri: urlComponents.path, 
                    headers: headers, 
                    body: body,
                    remoteAddress: remoteAddress
                )
            )
        }
    }
    
    /// An instance of your app, reset and configured before each test.
    public var app = A()
    public var Test: Builder { Builder(app: app) }

    open override func setUp() async throws {
        try await super.setUp()
        app = A()
        try await app.willRun()
    }

    open override func tearDown() async throws {
        try await super.tearDown()
        try await app.didRun()
        app.container.reset()
    }
}

extension Application {
    fileprivate var handler: HTTPHandler {
        container.require()
    }
}
