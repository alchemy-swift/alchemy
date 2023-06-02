@testable
import Alchemy
import AlchemyTest

final class QueryGroupingTests: TestCase<TestApp> {
    private let sampleWhere = SQLWhere(
        type: .value(key: "id", op: .equals, value: .int(1)),
        boolean: .and)
    
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testGroupBy() {
        XCTAssertEqual(DB.table("foo").groupBy("bar").query.groups, ["bar"])
        XCTAssertEqual(DB.table("foo").groupBy("bar").groupBy("baz").query.groups, ["bar", "baz"])
    }
    
    func testHaving() {
        let orWhere = SQLWhere(type: sampleWhere.type, boolean: .or)
        let query = DB.table("foo")
            .having(sampleWhere)
            .orHaving(orWhere)
            .having(key: "bar", op: .like, value: "baz", boolean: .or)
        XCTAssertEqual(query.query.havings, [
            sampleWhere,
            orWhere,
            SQLWhere(type: .value(key: "bar", op: .like, value: .string("baz")), boolean: .or)
        ])
    }
}
