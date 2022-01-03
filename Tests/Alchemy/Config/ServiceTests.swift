import AlchemyTest

final class ServiceTests: TestCase<TestApp> {
    func testAlchemyInject() {
        TestService.bind(TestService(bar: "one"))
        TestService.bind(.foo, TestService(bar: "two"))
        
        @Inject       var one: TestService
        @Inject(.foo) var two: TestService
        
        XCTAssertEqual(one.bar, "one")
        XCTAssertEqual(two.bar, "two")
    }
}
