import Alchemy
import Testing

struct ContentTypeTests {
    @Test func fileExtension() {
        #expect(ContentType(fileExtension: ".html") == .html)
    }

    @Test func invalidFileExtension() {
        #expect(ContentType(fileExtension: ".sc2save") == nil)
    }

    @Test func parameters() {
        let type = ContentType.multipart(boundary: "foo")
        #expect(type.value == "multipart/form-data")
        #expect(type.string == "multipart/form-data; boundary=foo")
    }

    @Test func equality() {
        let first = ContentType.multipart(boundary: "foo")
        let second = ContentType.multipart(boundary: "bar")
        #expect(first == second)
    }
}
