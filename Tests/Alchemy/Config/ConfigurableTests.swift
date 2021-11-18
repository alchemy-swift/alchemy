import AlchemyTest

final class ConfigurableTests: XCTestCase {
    func testDefaults() {
        XCTAssertEqual(TestService.foo, "bar")
        TestService.configureDefaults()
        XCTAssertEqual(TestService.foo, "baz")
    }
}
