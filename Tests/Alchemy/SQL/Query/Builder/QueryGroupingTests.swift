@testable
import Alchemy
import AlchemyTest

final class QueryGroupingTests: TestCase<TestApp> {
    private let sampleWhere = SQLWhere.and(.value(key: "id", op: .equals, value: .value(.int(1))))

    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testGroupBy() {
        XCTAssertEqual(DB.table("foo").groupBy("bar").groups, ["bar"])
        XCTAssertEqual(DB.table("foo").groupBy("bar").groupBy("baz").groups, ["bar", "baz"])
    }
    
    func testHaving() {
        let orWhere = SQLWhere.or(sampleWhere.type)
        let query = DB.table("foo")
            .having(sampleWhere)
            .orHaving(orWhere)
            .having(key: "bar", op: .like, value: "baz", boolean: .or)
        XCTAssertEqual(query.havings, [
            sampleWhere,
            orWhere,
            SQLWhere.or(.value(key: "bar", op: .like, value: .value(.string("baz"))))
        ])
    }
}
