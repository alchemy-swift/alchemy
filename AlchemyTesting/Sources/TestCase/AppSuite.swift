import Alchemy
import NIO

public protocol TestSuite {}

extension TestSuite {
    public var App: TestApp {
        Main as! TestApp
    }

    public var Test: TestBuilder<TestApp> {
        TestBuilder(app: App)
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
