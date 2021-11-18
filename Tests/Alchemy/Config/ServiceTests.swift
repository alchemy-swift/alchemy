import AlchemyTest

final class ServiceTests: TestCase<TestApp> {
    func testAlchemyInject() {
        TestService.register(TestService(bar: "one"))
        TestService.register(.foo, TestService(bar: "two"))
        
        @Inject       var one: TestService
        @Inject(.foo) var two: TestService
        
        XCTAssertEqual(one.bar, "one")
        XCTAssertEqual(two.bar, "two")
    }
}
