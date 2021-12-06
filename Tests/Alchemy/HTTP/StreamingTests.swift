@testable
import Alchemy
import AlchemyTest

final class StreamingTests: TestCase<TestApp> {
    func testClientRequestStream() async throws {
        Http.stub([
            ("*", .stub(body: .stream { write in
                try await write("foo")
                try await write("bar")
                try await write("baz")
            }))
        ])
        
        var res = try await Http.get("https://example.com/foo")
        try await res.collect()
            .assertOk()
            .assertBody("foobarbaz")
    }
    
    func testServerResponseStream() async throws {
        app.get("/stream") { _ in
            Response { write in
                try await write("foo")
                try await write("bar")
                try await write("baz")
            }
        }
        
        try await get("/stream")
            .collect()
            .assertOk()
            .assertBody("foobarbaz")
    }
    
    func testEndToEndStream() async throws {
        app.get("/stream") { _ in
            Response { write in
                try await write("foo")
                try await write("bar")
                try await write("baz")
            }
        }
        
        try app.start()
        
        try await Http.get("http://localhost:3000/stream")
            .assertStream { buffer in
                XCTAssertEqual(buffer.string(), "foo")
            }
            .assertOk()
            .assertBody("foobarbaz")
    }
    
    func testFileRequest() {
        
    }
    
    func testFileResponse() {
        
    }
    
    func testFileEndToEnd() {
        
    }
}
