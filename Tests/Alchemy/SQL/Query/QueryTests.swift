@testable
import Alchemy
import AlchemyTest

final class QueryTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testStartsEmpty() {
        let query = Database.table("foo")
        XCTAssertEqual(query.table, "foo")
        XCTAssertEqual(query.columns, ["*"])
        XCTAssertEqual(query.isDistinct, false)
        XCTAssertNil(query.limit)
        XCTAssertNil(query.offset)
        XCTAssertNil(query.lock)
        XCTAssertEqual(query.joins, [])
        XCTAssertEqual(query.wheres, [])
        XCTAssertEqual(query.groups, [])
        XCTAssertEqual(query.havings, [])
        XCTAssertEqual(query.orders, [])
    }
    
    func testEquality() {
        XCTAssertEqual(Database.table("foo"), Database.table("foo"))
        XCTAssertNotEqual(Database.table("foo"), Database.table("bar"))
    }
}
