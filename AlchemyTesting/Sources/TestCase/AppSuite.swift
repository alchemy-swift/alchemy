import Alchemy
import NIO

public protocol AppSuite {
    associatedtype A: Application
    var app: A { get }
}

extension AppSuite {
    public var Test: TestBuilder<A> {
        TestBuilder(app: app)
    }

    public func withApp(execute: (A) async throws -> Void) async throws {
        try await app.willTest()
        try await execute(app)
        try await app.didTest()
    }
}

public final class TestBuilder<A: Application>: RequestBuilder {
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
        await Handle.handle(
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
