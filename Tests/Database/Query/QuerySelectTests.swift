@testable
import Alchemy
import AlchemyTest

final class QuerySelectTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        DB.stub()
    }
    
    func testStartsEmpty() {
        let query = DB.table("foo")
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
    
    func testSelect() {
        let specific = DB.table("foo").select(["bar", "baz"])
        XCTAssertEqual(specific.columns, ["bar", "baz"])
        let all = DB.table("foo").select()
        XCTAssertEqual(all.columns, ["*"])
    }
    
    func testDistinct() {
        XCTAssertEqual(DB.table("foo").distinct().isDistinct, true)
    }
}
