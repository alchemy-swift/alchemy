@testable
import Alchemy
import AlchemyTest

final class DatabaseQueryTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testTable() {
        XCTAssertEqual(DB.table("foo").table, "foo")
    }
    
    func testAlias() {
        XCTAssertEqual(DB.table("foo", as: "bar").table, "foo AS bar")
    }
}
