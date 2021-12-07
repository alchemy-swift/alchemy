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
    
    func testClientRequestStream() async throws {
        try await Http
            .withAttachment("fileFoo", file: try await Storage.get("foo"))
            .withAttachment("fileBar", file: try await Storage.get("bar"))
            .post("foo")
    }
    
    func testServerResponseStream() async throws {
        app.get("/stream") { _ in
            Response {
                try await $0.write("foo")
                try await $0.write("bar")
                try await $0.write("baz")
            }
        }
        
        try await get("/stream")
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
    
    func testFileResponse() {
        
    }
    
    func testFileEndToEnd() {
        
    }
}
