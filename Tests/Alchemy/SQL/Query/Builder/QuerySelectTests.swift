@testable
import Alchemy
import AlchemyTest

final class QuerySelectTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testStartsEmpty() {
        let query = DB.table("foo")
        XCTAssertEqual(query.query.table, "foo")
        XCTAssertEqual(query.query.columns, ["*"])
        XCTAssertEqual(query.query.isDistinct, false)
        XCTAssertNil(query.query.limit)
        XCTAssertNil(query.query.offset)
        XCTAssertNil(query.query.lock)
        XCTAssertEqual(query.query.joins, [])
        XCTAssertEqual(query.query.wheres, [])
        XCTAssertEqual(query.query.groups, [])
        XCTAssertEqual(query.query.havings, [])
        XCTAssertEqual(query.query.orders, [])
    }
    
    func testSelect() {
        let specific = DB.table("foo").select(["bar", "baz"])
        XCTAssertEqual(specific.query.columns, ["bar", "baz"])
        let all = DB.table("foo").select()
        XCTAssertEqual(all.query.columns, ["*"])
    }
    
    func testDistinct() {
        XCTAssertEqual(DB.table("foo").distinct().query.isDistinct, true)
    }
}
