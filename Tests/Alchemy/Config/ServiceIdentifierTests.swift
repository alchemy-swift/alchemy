import AlchemyTest

final class ServiceIdentifierTests: XCTestCase {
    func testServiceIdentifier() {
        let intId: ServiceIdentifier<TestApp> = 1
        let stringId: ServiceIdentifier<TestApp> = "one"
        let nilId: ServiceIdentifier<TestApp> = nil
        
        XCTAssertNotEqual(intId, .default)
        XCTAssertNotEqual(stringId, .default)
        XCTAssertEqual(nilId, .default)
    }
}
