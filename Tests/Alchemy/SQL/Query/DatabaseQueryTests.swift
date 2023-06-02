@testable
import Alchemy
import AlchemyTest

final class DatabaseQueryTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testTable() {
        XCTAssertEqual(DB.from("foo").query.table, "foo")
    }
    
    func testAlias() {
        XCTAssertEqual(DB.from("foo", as: "bar").query.table, "foo as bar")
    }
}
