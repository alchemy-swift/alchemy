import Alchemy
import Testing

struct ResponseConvertibleTests {
    @Test func convert() throws {
        let array = ["one", "two"]
        let res = try array.response()
        #expect(res.status == .ok)
        #expect(try res.decode() == array)
    }
}

extension [String]: ResponseConvertible {}
