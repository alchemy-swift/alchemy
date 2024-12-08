import Alchemy
import MultipartKit
import Testing

struct ResponseTests {
    @Test func basic() throws {
        let res = Response(status: .created, headers: [.allow: "1", .accept: "2"])
        #expect(res.header(.allow) == "1")
        #expect(res.header(.accept) == "2")
        #expect(res.header(.contentLength) == "0")
        #expect(res.status == .created)
    }

    @Test func body() {
        let res = Response(status: .ok, string: "foo")
        #expect(res.body?.string == "foo")
        #expect(res.header(.contentLength) == "3")
        #expect(res.status == .ok)
    }

    @Test func jsonEncode() throws {
        let res = try Response(encodable: Fixtures.object, encoder: .json)
        #expect(res.headers.contentType == .json)
        #expect(res.body?.string == Fixtures.jsonString || res.body?.string == Fixtures.altJsonString)
    }

    @Test func jsonDecode() throws {
        let res = Response(string: Fixtures.jsonString, contentType: .json)
        #expect(try res.decode() == Fixtures.object)
    }

    @Test func urlEncode() throws {
        let res = try Response(encodable: Fixtures.object, encoder: .urlForm)
        #expect(res.headers.contentType == .urlForm)
        #expect(res.body?.string == Fixtures.urlString || res.body?.string == Fixtures.urlStringAlternate)
    }

    @Test func urlDecode() throws {
        let res = Response(string: Fixtures.urlString, contentType: .urlForm)
        #expect(try res.decode() == Fixtures.object)
    }

    @Test func multipartEncode() throws {
        FormDataEncoder.boundary = { Fixtures.multipartBoundary }
        let res = try Response(encodable: Fixtures.object, encoder: .multipart)
        #expect(res.headers.contentType == .multipart(boundary: Fixtures.multipartBoundary))
        #expect(res.body?.string == Fixtures.multipartString)
    }

    @Test func multipartDecode() throws {
        FormDataEncoder.boundary = { Fixtures.multipartBoundary }
        let res = Response(string: Fixtures.multipartString, contentType: .multipart(boundary: Fixtures.multipartBoundary))
        #expect(try res.decode() == Fixtures.object)
    }
}


private struct Fixtures {
    struct Test: Codable, Equatable {
        var foo = "foo"
        var bar = "bar"
    }
    
    static let jsonString = """
        {"foo":"foo","bar":"bar"}
        """
    
    static let altJsonString = """
        {"bar":"bar","foo":"foo"}
        """
    
    static let urlString = "foo=foo&bar=bar"
    static let urlStringAlternate = "bar=bar&foo=foo"
    
    static let multipartBoundary = "foo123"
    
    static let multipartString = """
        --foo123\r
        Content-Disposition: form-data; name=\"foo\"\r
        \r
        foo\r
        --foo123\r
        Content-Disposition: form-data; name=\"bar\"\r
        \r
        bar\r
        --foo123--\r
        
        """
    
    static let object = Test()
}
