import Alchemy
import Foundation
import NIO

public var Test: TestClient {
    TestClient()
}

public struct TestClient: RequestBuilder {
    public var urlComponents = URLComponents()
    public var method: HTTPRequest.Method = .get
    public var headers: HTTPFields = [:]
    public var body: Bytes? = nil
    private var remoteAddress: SocketAddress? = nil

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
