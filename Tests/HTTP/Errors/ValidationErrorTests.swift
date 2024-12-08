import Alchemy
import Testing

struct ValidationErrorTests {
    @Test func response() throws {
        let res = try ValidationError("bar").response()
        #expect(res.status == .badRequest)
        #expect(try res.decode() == ["validation_error": "bar"])
    }
}
