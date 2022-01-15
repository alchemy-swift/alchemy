import AlchemyTest

final class ServiceIdentifierTests: XCTestCase {
    func testServiceIdentifier() {
        struct TestIdentifier: ServiceIdentifier {
            private let hashable: AnyHashable
            init(hashable: AnyHashable) { self.hashable = hashable }
        }
        
        let intId: TestIdentifier = 1
        let stringId: TestIdentifier = "one"
        let nilId: TestIdentifier = .init(hashable: AnyHashable(nil as AnyHashable?))
        
        XCTAssertNotEqual(intId, .default)
        XCTAssertNotEqual(stringId, .default)
        XCTAssertEqual(nilId, .default)
        XCTAssertEqual(1.hashValue, TestIdentifier(hashable: 1).hashValue)
    }
}
