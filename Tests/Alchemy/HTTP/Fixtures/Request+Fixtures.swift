@testable
import Alchemy
import NIOHTTP1

extension Request {
    static func fixture(
        version: HTTPVersion = .http1_1,
        method: HTTPMethod = .GET,
        uri: String = "/path",
        headers: HTTPHeaders = HTTPHeaders(),
        body: ByteBuffer? = nil
    ) -> Request {
        Request(head: HTTPRequestHead(version: version, method: method, uri: uri, headers: headers), bodyBuffer: body)
    }
}
