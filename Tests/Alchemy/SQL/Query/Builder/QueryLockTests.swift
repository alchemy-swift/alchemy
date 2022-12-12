@testable
import Alchemy
import AlchemyTest

final class QueryLockTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testLock() {
        XCTAssertNil(DB.table("foo").lock)
        XCTAssertEqual(DB.table("foo").lock(for: .update).lock, SQLQuery.Lock(strength: .update, option: nil))
        XCTAssertEqual(DB.table("foo").lock(for: .share).lock, SQLQuery.Lock(strength: .share, option: nil))
        XCTAssertEqual(DB.table("foo").lock(for: .update, option: .noWait).lock, SQLQuery.Lock(strength: .update, option: .noWait))
        XCTAssertEqual(DB.table("foo").lock(for: .update, option: .skipLocked).lock, SQLQuery.Lock(strength: .update, option: .skipLocked))
    }
}
