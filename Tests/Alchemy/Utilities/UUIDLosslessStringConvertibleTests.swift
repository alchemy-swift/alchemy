import AlchemyTest

final class UUIDLosslessStringConvertibleTests: XCTestCase {
    func testValidUUID() {
        let uuid = UUID()
        XCTAssertEqual(UUID(uuid.uuidString), uuid)
    }
    
    func testInvalidUUID() {
        XCTAssertEqual(UUID("foo"), nil)
    }
}
