@testable
import Alchemy
import AlchemyTest

final class DatabaseQueryTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testTable() {
        XCTAssertEqual(Database.from("foo").table, "foo")
        XCTAssertEqual(Database.default.from("foo").table, "foo")
    }
    
    func testAlias() {
        XCTAssertEqual(Database.from("foo", as: "bar").table, "foo as bar")
        XCTAssertEqual(Database.default.from("foo", as: "bar").table, "foo as bar")
    }
}
