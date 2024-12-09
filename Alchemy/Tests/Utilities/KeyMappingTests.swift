import Alchemy
import Testing

struct KeyMappingTests {
    @Test func custom() {
        let custom = KeyMapping.custom(to: { "\($0)_1" }, from: { String($0.dropLast(2)) })
        #expect(custom.encode("foo") == "foo_1")
    }

    @Test func snakeCase() {
        let snakeCase = KeyMapping.snakeCase
        #expect(snakeCase.encode("") == "")
        #expect(snakeCase.encode("foo") == "foo")
        #expect(snakeCase.encode("fooBar") == "foo_bar")
        #expect(snakeCase.encode("AI") == "a_i")
        #expect(snakeCase.encode("testJSON") == "test_json")
        #expect(snakeCase.encode("testNumbers123") == "test_numbers123")
    }
}
