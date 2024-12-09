@testable
import Alchemy
import AlchemyTesting

struct FileTests {
    @Test func metadata() {
        let file = File(name: "foo.html", source: .raw, content: "<p>foo</p>", size: 10)
        #expect(file.extension == "html")
        #expect(file.size == 10)
        #expect(file.contentType == .html)
    }

    @Test func invalidURL() {
        let file = File(name: "", source: .raw, content: "foo", size: 3)
        #expect(file.extension.isEmpty)
    }
}
