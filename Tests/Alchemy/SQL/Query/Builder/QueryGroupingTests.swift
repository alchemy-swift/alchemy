@testable
import Alchemy
import AlchemyTest

final class QueryGroupingTests: TestCase<TestApp> {
    private let sampleWhere = Query.Where(
        type: .value(key: "id", op: .equals, value: .int(1)),
        boolean: .and)
    
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testGroupBy() {
        XCTAssertEqual(DB.table("foo").groupBy("bar").groups, ["bar"])
        XCTAssertEqual(DB.table("foo").groupBy("bar").groupBy("baz").groups, ["bar", "baz"])
    }
    
    func testHaving() {
        let orWhere = Query.Where(type: sampleWhere.type, boolean: .or)
        let query = DB.table("foo")
            .having(sampleWhere)
            .orHaving(orWhere)
            .having(key: "bar", op: .like, value: "baz", boolean: .or)
        XCTAssertEqual(query.havings, [
            sampleWhere,
            orWhere,
            Query.Where(type: .value(key: "bar", op: .like, value: .string("baz")), boolean: .or)
        ])
    }
}
