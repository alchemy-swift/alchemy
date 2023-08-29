//@testable
//import Alchemy
//import AlchemyTest
//
//final class DatabaseQueryTests: TestCase<TestApp> {
//    override func setUp() {
//        super.setUp()
//        Database.stub()
//    }
//    
//    func testTable() {
//        XCTAssertEqual(DB.from("foo").table, "foo")
//    }
//    
//    func testAlias() {
//        XCTAssertEqual(DB.from("foo", as: "bar").table, "foo as bar")
//    }
//}
