@testable
import Alchemy
import Foundation
import Testing

struct RequestTests {
    let sampleBase64Credentials = Data("username:password".utf8).base64EncodedString()
    let sampleToken = UUID().uuidString

    @Test func path() {
        #expect(Request.fake(uri: "/foo/bar").path == "/foo/bar")
    }

    @Test func queryItems() {
        #expect(Request.fake(uri: "/path").queryItems == nil)
        #expect(Request.fake(uri: "/path?foo=1&bar=2").queryItems == [
            URLQueryItem(name: "foo", value: "1"),
            URLQueryItem(name: "bar", value: "2")
        ])
    }

    @Test func parameter() {
        let request = Request.fake()
        request.parameters = [
            Request.Parameter(key: "foo", value: "one"),
            Request.Parameter(key: "bar", value: "two"),
            Request.Parameter(key: "baz", value: "three"),
        ]
        #expect(request.parameter("foo") == "one")
        #expect(request.parameter("bar") == "two")
        #expect(request.parameter("baz") == "three")
        #expect(request.parameter("fake", as: String.self) == nil)
        #expect(request.parameter("foo", as: Int.self) == nil)
        #expect(request.parameters.contains(Request.Parameter(key: "foo", value: "one")))
    }

    @Test func body() {
        #expect(Request.fake(body: nil).body == nil)
        #expect(Request.fake(body: .empty).body != nil)
    }

    @Test func decodeBodyJSON() throws {
        struct ExpectedJSON: Codable, Equatable {
            var foo = "bar"
        }

        #expect(throws: Error.self) { try Request.fake(body: nil).decode(ExpectedJSON.self) }
        #expect(throws: Error.self) { try Request.fake(body: .empty).decode(ExpectedJSON.self) }
        #expect(try Request.fake(body: .json).decode() == ExpectedJSON())
    }

    // MARK: Parameters

    @Test func stringConversion() {
        #expect(Request.Parameter(key: "foo", value: "bar").string() == "bar")
    }

    @Test func intConversion() throws {
        #expect(try Request.Parameter(key: "foo", value: "1").int() == 1)
        #expect(throws: Error.self) { try Request.Parameter(key: "foo", value: "foo").int() }
    }

    @Test func uuidConversion() throws {
        let uuid = UUID()
        #expect(try Request.Parameter(key: "foo", value: uuid.uuidString).uuid() == uuid)
        #expect(throws: Error.self) { try Request.Parameter(key: "foo", value: "foo").uuid() }
    }

    // MARK: Auth

    @Test func noAuth() {
        #expect(Request.fake().basicAuth() == nil)
        #expect(Request.fake().bearerAuth() == nil)
        #expect(Request.fake().getAuth() == nil)
    }

    @Test func unknownAuth() {
        let request = Request.fake(headers: [.authorization: "Foo \(sampleToken)"])
        #expect(request.getAuth() == nil)
    }

    @Test func bearerAuth() {
        let request = Request.fake(headers: [.authorization: "Bearer \(sampleToken)"])
        #expect(request.basicAuth() == nil)
        #expect(request.bearerAuth() != nil)
        #expect(request.bearerAuth()?.token == sampleToken)
    }

    @Test func basicAuth() {
        let request = Request.fake(headers: [.authorization: "Basic \(sampleBase64Credentials)"])
        #expect(request.bearerAuth() == nil)
        #expect(request.basicAuth() != nil)
        #expect(request.basicAuth() == Request.Auth.Basic(username: "username", password: "password"))
    }

    @Test func malformedBasicAuth() {
        let notBase64Encoded = Request.fake(headers: [.authorization: "Basic user:pass"])
        #expect(notBase64Encoded.basicAuth() == nil)
        let empty = Request.fake(headers: [.authorization: "Basic "])
        #expect(empty.basicAuth() == nil)
    }

    // MARK: Associated Values

    @Test func value() throws {
        let request = Request.fake()
        request.set("foo")
        #expect(try request.get() == "foo")
    }

    @Test func overwrite() throws {
        let request = Request.fake()
        request.set("foo")
        request.set("bar")
        #expect(try request.get() == "bar")
    }

    @Test func noValue() {
        let request = Request.fake()
        request.set(1)
        #expect(throws: Error.self) { try request.get(String.self) }
    }
}


fileprivate extension Bytes {
    static var empty: Bytes {
        .buffer(ByteBuffer())
    }
    
    static var json: Bytes {
        .string("""
            {"foo":"bar"}
            """)
    }
}
