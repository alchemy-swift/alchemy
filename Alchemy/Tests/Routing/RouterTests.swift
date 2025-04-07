@testable
import Alchemy
import AlchemyTesting
import Foundation

@Suite(.mockTestApp)
struct RouterTests {
    @Test func testResponseConvertibleHandlers() async throws {
        Main.get("/string") { _ in "one" }
        Main.post("/string") { _ in "two" }
        Main.put("/string") { _ in "three" }
        Main.patch("/string") { _ in "four" }
        Main.delete("/string") { _ in "five" }
        Main.options("/string") { _ in "six" }
        Main.head("/string") { _ in "seven" }

        try await Test.get("/string").expectBody("one").expectOk()
        try await Test.post("/string").expectBody("two").expectOk()
        try await Test.put("/string").expectBody("three").expectOk()
        try await Test.patch("/string").expectBody("four").expectOk()
        try await Test.delete("/string").expectBody("five").expectOk()
        try await Test.options("/string").expectBody("six").expectOk()
        try await Test.head("/string").expectBody("seven").expectOk()
    }
    
    @Test func testVoidHandlers() async throws {
        Main.get("/void") { _ in }
        Main.post("/void") { _ in }
        Main.put("/void") { _ in }
        Main.patch("/void") { _ in }
        Main.delete("/void") { _ in }
        Main.options("/void") { _ in }
        Main.head("/void") { _ in }

        try await Test.get("/void").expectEmpty().expectOk()
        try await Test.post("/void").expectEmpty().expectOk()
        try await Test.put("/void").expectEmpty().expectOk()
        try await Test.patch("/void").expectEmpty().expectOk()
        try await Test.delete("/void").expectEmpty().expectOk()
        try await Test.options("/void").expectEmpty().expectOk()
        try await Test.head("/void").expectEmpty().expectOk()
    }
    
    @Test func testEncodableHandlers() async throws {
        Main.get("/encodable") { _ in 1 }
        Main.post("/encodable") { _ in 2 }
        Main.put("/encodable") { _ in 3 }
        Main.patch("/encodable") { _ in 4 }
        Main.delete("/encodable") { _ in 5 }
        Main.options("/encodable") { _ in 6 }
        Main.head("/encodable") { _ in 7 }

        try await Test.get("/encodable").expectBody("1").expectOk()
        try await Test.post("/encodable").expectBody("2").expectOk()
        try await Test.put("/encodable").expectBody("3").expectOk()
        try await Test.patch("/encodable").expectBody("4").expectOk()
        try await Test.delete("/encodable").expectBody("5").expectOk()
        try await Test.options("/encodable").expectBody("6").expectOk()
        try await Test.head("/encodable").expectBody("7").expectOk()
    }
    
    @Test func testMissing() async throws {
        Main.get("/foo") { _ in }
        Main.post("/bar") { _ in }
        try await Test.post("/foo").expectNotFound()
    }

    @Test func testQueriesIgnored() async throws {
        Main.get("/foo") { _ in }
        try await Test.get("/foo?query=1").expectEmpty().expectOk()
    }

    @Test func testPathParametersMatch() async throws {
        var one = false
        let uuidString = UUID().uuidString
        Main.get("/v1/some_path/:uuid/:user_id") {
            #expect($0.parameters == [
                Request.Parameter(key: "uuid", value: uuidString),
                Request.Parameter(key: "user_id", value: "123"),
            ])
            one = true
            return "foo"
        }
        
        try await Test.get("/v1/some_path/\(uuidString)/123").expectBody("foo").expectOk()
        #expect(one)
    }

    @Test func testMultipleRequests() async throws {
        Main.get("/foo") { _ in 1 }
        Main.get("/foo") { _ in 2 }
        try await Test.get("/foo").expectOk().expectBody("1")
    }

    @Test(.disabled())
    func testInvalidPath() throws {}

    @Test func forwardSlashIssues() async throws {
        Main.get("noslash") { _ in 1 }
        Main.get("wrongslash/") { _ in 2 }
        Main.get("//////////manyslash//////////////") { _ in 3 }
        Main.get("split/path") { _ in 4 }
        try await Test.get("/noslash").expectOk().expectBody("1")
        try await Test.get("/wrongslash").expectOk().expectBody("2")
        try await Test.get("/manyslash").expectOk().expectBody("3")
        try await Test.get("/splitpath").expectNotFound()
        try await Test.get("/split/path").expectOk().expectBody("4")
    }

    @Test func groupedPathPrefix() async throws {
        Main
            .grouping("group") { app in
                app
                    .get("/foo") { _ in 1 }
                    .get("/bar") { _ in 2 }
                    .grouping("/nested") { app in
                        app.post("/baz") { _ in 3 }
                    }
                    .post("/bar") { _ in 4 }
            }
            .put("/foo") { _ in 5 }
        
        try await Test.get("/group/foo").expectOk().expectBody("1")
        try await Test.get("/group/bar").expectOk().expectBody("2")
        try await Test.post("/group/nested/baz").expectOk().expectBody("3")
        try await Test.post("/group/bar").expectOk().expectBody("4")

        // defined outside group -> still available without group prefix
        try await Test.put("/foo").expectOk().expectBody("5")

        // only available under group prefix
        try await Test.get("/bar").expectNotFound()
        try await Test.post("/baz").expectNotFound()
        try await Test.post("/bar").expectNotFound()
        try await Test.get("/foo").expectNotFound()
    }
    
    @Test func error() async throws {
        Main.get("/error") { _ -> Void in throw TestError() }
        let status = HTTPResponse.Status.internalServerError
        try await Test.get("/error").expectStatus(status).expectBody("500 Internal Server Error")
    }
    
    @Test func errorHandling() async throws {
        Main.get("/error_convert") { _ -> Void in throw TestConvertibleError() }
        Main.get("/error_convert_error") { _ -> Void in throw TestThrowingConvertibleError() }

        let errorStatus = HTTPResponse.Status.internalServerError
        try await Test.get("/error_convert").expectStatus(.badGateway).expectEmpty()
        try await Test.get("/error_convert_error").expectStatus(errorStatus).expectBody("500 Internal Server Error")
    }

    // MARK: Streaming

    @Test func serverResponseStream() async throws {
        Main.get("/stream") { _ in
            Response {
                $0.write(ByteBuffer(string: "foo"))
                $0.write(ByteBuffer(string: "bar"))
                $0.write(ByteBuffer(string: "baz"))
            }
        }

        try await Test.get("/stream")
            .collect()
            .expectOk()
            .expectBody("foobarbaz")
    }

    @Test func endToEndStream() async throws {
        Main.get("/stream", options: .stream) { _ in
            Response {
                $0.write(ByteBuffer(string: "foo"))
                $0.write(ByteBuffer(string: "bar"))
                $0.write(ByteBuffer(string: "baz"))
            }
        }

        Main.background()

        var expected = ["foo", "bar", "baz"]
        try await Http
            .withStream()
            .get("http://localhost:3000/stream")
            .expectStream {
                guard expected.first != nil else {
                    Issue.record("There were too many stream elements.")
                    return
                }

                #expect($0.string == expected.removeFirst())
            }
            .expectOk()
    }

    @Test func fileRequest() async throws {
        Main.get("/stream") { _ in
            Response {
                $0.write(ByteBuffer(string: "foo"))
                $0.write(ByteBuffer(string: "bar"))
                $0.write(ByteBuffer(string: "baz"))
            }
        }

        try await Test.get("/stream")
            .collect()
            .expectOk()
            .expectBody("foobarbaz")
    }
}

private struct TestError: Error {}

private struct TestConvertibleError: Error, ResponseConvertible {
    func response() async throws -> Response {
        Response(status: .badGateway)
    }
}

private struct TestThrowingConvertibleError: Error, ResponseConvertible {
    func response() async throws -> Response {
        throw TestError()
    }
}
