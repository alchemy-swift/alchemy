@testable
import Alchemy
import AlchemyTest

final class QueryOrderTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
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
