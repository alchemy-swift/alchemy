@testable
import Alchemy
import AlchemyTest
import NIOCore

final class StreamingTests: TestCase<TestApp> {
    
    // MARK: - Client
    
    func testClientResponseStream() async throws {
        Http.stub([
            ("*", .stub(body: .stream {
                try await $0.write("foo")
                try await $0.write("bar")
                try await $0.write("baz")
            }))
        ])
        
        var res = try await Http.get("https://example.com/foo")
        try await res.collect()
            .assertOk()
            .assertBody("foobarbaz")
    }
    
    func testServerResponseStream() async throws {
        app.get("/stream") { _ in
            Response {
                try await $0.write("foo")
                try await $0.write("bar")
                try await $0.write("baz")
            }
        }
        
        try await Test.get("/stream")
            .collect()
            .assertOk()
            .assertBody("foobarbaz")
    }
    
    func testEndToEndStream() async throws {
        app.get("/stream") { _ in
            Response {
                try await $0.write("foo")
                try await $0.write("bar")
                try await $0.write("baz")
            }
        }
        
        try app.start()
        var expected = ["foo", "bar", "baz"]
        try await Http.get("http://localhost:3000/stream")
            .assertStream {
                guard expected.first != nil else {
                    XCTFail("There were too many stream elements.")
                    return
                }
                
                XCTAssertEqual($0.string(), expected.removeFirst())
            }
            .assertOk()
    }
    
    func testFileRequest() {
        app.get("/stream") { _ in
            Response {
                try await $0.write("foo")
                try await $0.write("bar")
                try await $0.write("baz")
            }
        }
    }
}
