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
        Response(status: .ok, body: "foo")
            .assertHeader("Content-Length", value: "3")
            .assertBody("foo")
            .assertOk()
    }
    
    func testResponseWrite() async throws {
        let expHead = expectation(description: "write head")
        let expBody = expectation(description: "write body")
        let expEnd = expectation(description: "write end")
        let writer = TestResponseWriter { status, headers in
            XCTAssertEqual(status, .ok)
            XCTAssertEqual(headers.first(name: "content-type"), "text/plain")
            XCTAssertEqual(headers.first(name: "content-length"), "3")
            expHead.fulfill()
        } didWriteBody: { body in
            XCTAssertEqual(body.string(), "foo")
            expBody.fulfill()
        } didWriteEnd: {
            expEnd.fulfill()
        }

        try await writer.write(response: Response(status: .ok, body: "foo"))
        await waitForExpectations(timeout: kMinTimeout)
    }
    
    func testCustomWriteResponse() async throws {
        let expHead = expectation(description: "write head")
        let expBody = expectation(description: "write body")
        expBody.expectedFulfillmentCount = 2
        let expEnd = expectation(description: "write end")
        var bodyWriteCount = 0
        let writer = TestResponseWriter { status, headers in
            XCTAssertEqual(status, .created)
            XCTAssertEqual(headers.first(name: "foo"), "one")
            expHead.fulfill()
        } didWriteBody: { body in
            if bodyWriteCount == 0 {
                XCTAssertEqual(body.string(), "bar")
                bodyWriteCount += 1
            } else {
                XCTAssertEqual(body.string(), "baz")
            }
            
            expBody.fulfill()
        } didWriteEnd: {
            expEnd.fulfill()
        }

        try await writer.write(response: Response {
            try await $0.writeHead(status: .created, ["foo": "one"])
            try await $0.writeBody(ByteBuffer(string: "bar"))
            try await $0.writeBody(ByteBuffer(string: "baz"))
            try await $0.writeEnd()
        })
        
        await waitForExpectations(timeout: kMinTimeout)
    }
}

struct TestResponseWriter: ResponseWriter {
    var didWriteHead: (HTTPResponseStatus, HTTPHeaders) -> Void
    var didWriteBody: (ByteBuffer) -> Void
    var didWriteEnd: () -> Void
    
    func writeHead(status: HTTPResponseStatus, _ headers: HTTPHeaders) {
        didWriteHead(status, headers)
    }
    
    func writeBody(_ body: ByteBuffer) {
        didWriteBody(body)
    }
    
    func writeEnd() {
        didWriteEnd()
    }
}
