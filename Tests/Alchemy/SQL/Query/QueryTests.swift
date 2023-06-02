@testable
import Alchemy
import AlchemyTest

final class QueryTests: TestCase<TestApp> {
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
    
    func testEquality() {
        XCTAssertEqual(DB.table("foo").query, DB.table("foo").query)
        XCTAssertNotEqual(DB.table("foo").query, DB.table("bar").query)
    }
}
