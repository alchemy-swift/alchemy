@testable
import Alchemy
import AlchemyTest

final class ResponseTests: XCTestCase {
    func testInit() throws {
        Response(status: .created, headers: ["foo": "1", "bar": "2"])
            .assertHeader("foo", value: "1")
            .assertHeader("bar", value: "2")
            .assertHeader("Content-Length", value: "0")
            .assertCreated()
    }
    
    func testInitContentLength() {
        Response(status: .ok)
            .withString("foo")
            .assertHeader("Content-Length", value: "3")
            .assertBody("foo")
            .assertOk()
    }
}
