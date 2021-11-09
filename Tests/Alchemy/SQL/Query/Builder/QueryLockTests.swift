@testable
import Alchemy
import AlchemyTest

final class QueryLockTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testLock() {
        XCTAssertNil(Database.table("foo").lock)
        XCTAssertEqual(Database.table("foo").lock(for: .update).lock, Query.Lock(strength: .update, option: nil))
        XCTAssertEqual(Database.table("foo").lock(for: .share).lock, Query.Lock(strength: .share, option: nil))
        XCTAssertEqual(Database.table("foo").lock(for: .update, option: .noWait).lock, Query.Lock(strength: .update, option: .noWait))
        XCTAssertEqual(Database.table("foo").lock(for: .update, option: .skipLocked).lock, Query.Lock(strength: .update, option: .skipLocked))
    }
}
