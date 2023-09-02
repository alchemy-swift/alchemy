@testable
import Alchemy
import AlchemyTest

final class QueryPagingTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testLimit() {
        XCTAssertEqual(DB.table("foo").distinct().isDistinct, true)
    }
    
    func testOffset() {
        XCTAssertEqual(DB.table("foo").distinct().isDistinct, true)
    }
    
    func testPaging() {
        let standardPage = DB.table("foo").page(4)
        XCTAssertEqual(standardPage.limit, 100)
        XCTAssertEqual(standardPage.offset, 300)
        
        let customPage = DB.table("foo").page(2, pageSize: 10)
        XCTAssertEqual(customPage.limit, 10)
        XCTAssertEqual(customPage.offset, 10)
    }
}
