import Alchemy
import Testing

struct HTTPErrorTests {
    @Test func response() throws {
        let res = try HTTPError(.badGateway, message: "foo").response()
        #expect(res.status == .badGateway)
        #expect(try res.decode() == ["message": "foo"])
    }
}
