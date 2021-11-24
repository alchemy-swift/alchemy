@testable
import Alchemy
import AlchemyTest

final class QueryPagingTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testLimit() {
        XCTAssertEqual(Database.table("foo").distinct().isDistinct, true)
    }
    
    func testOffset() {
        XCTAssertEqual(Database.table("foo").distinct().isDistinct, true)
    }
    
    func testPaging() {
        let standardPage = Database.table("foo").forPage(4)
        XCTAssertEqual(standardPage.limit, 25)
        XCTAssertEqual(standardPage.offset, 75)
        
        let customPage = Database.table("foo").forPage(2, perPage: 10)
        XCTAssertEqual(customPage.limit, 10)
        XCTAssertEqual(customPage.offset, 10)
    }
}
