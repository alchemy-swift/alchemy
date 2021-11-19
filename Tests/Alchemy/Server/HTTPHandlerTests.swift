@testable
import Alchemy
import AlchemyTest
import NIO
import NIOHTTP1

final class HTTPHanderTests: XCTestCase {
    func testServe() async throws {
        let app = TestApp()
        try app.setup()
        app.get("/foo", use: { _ in "hello" })
        app.start("serve")
        defer { app.stop() }
        try await Http.get("http://localhost:3000/foo")
            .assertBody("hello")
    }
}
