@testable
import Alchemy
import AlchemyTesting

final class QueryLockTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        DB.stub()
    }
    
    func testLock() {
        XCTAssertNil(DB.table("foo").lock)
        XCTAssertEqual(DB.table("foo").lock(for: .update).lock, SQLLock(strength: .update, option: nil))
        XCTAssertEqual(DB.table("foo").lock(for: .share).lock, SQLLock(strength: .share, option: nil))
        XCTAssertEqual(DB.table("foo").lock(for: .update, option: .noWait).lock, SQLLock(strength: .update, option: .noWait))
        XCTAssertEqual(DB.table("foo").lock(for: .update, option: .skipLocked).lock, SQLLock(strength: .update, option: .skipLocked))
    }
}
