@testable
import Alchemy
import AlchemyTest

final class QueryPagingTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testLimit() {
        XCTAssertEqual(DB.table("foo").distinct().query.isDistinct, true)
    }
    
    func testOffset() {
        XCTAssertEqual(DB.table("foo").distinct().query.isDistinct, true)
    }
    
    func testPaging() {
        let standardPage = DB.table("foo").forPage(4)
        XCTAssertEqual(standardPage.query.limit, 25)
        XCTAssertEqual(standardPage.query.offset, 75)
        
        let customPage = DB.table("foo").forPage(2, perPage: 10)
        XCTAssertEqual(customPage.query.limit, 10)
        XCTAssertEqual(customPage.query.offset, 10)
    }
}
