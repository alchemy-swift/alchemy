import AlchemyTest

final class StringInitializableTests: XCTestCase {
    func testValidUUID() async throws {
        let uuid = UUID()
        XCTAssertEqual(UUID(uuid.uuidString), uuid)
    }
    
    func testInvalidUUID() async throws {
        XCTAssertEqual(UUID("foo"), nil)
    }
}
