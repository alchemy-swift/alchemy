@testable
import Alchemy
import AlchemyTesting

final class QueryOrderTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        DB.stub()
    }
    
    func testOrderBy() {
        let query = DB.table("foo")
            .orderBy("bar")
            .orderBy("baz", direction: .desc)
        XCTAssertEqual(query.orders, [
            SQLOrder(column: "bar", direction: .asc),
            SQLOrder(column: "baz", direction: .desc),
        ])
    }
}
