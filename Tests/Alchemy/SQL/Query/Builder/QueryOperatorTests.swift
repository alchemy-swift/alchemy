@testable
import Alchemy
import AlchemyTest

final class QueryOperatorTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testOperatorDescriptions() {
        XCTAssertEqual(SQLQuery.Operator.equals.description, "=")
        XCTAssertEqual(SQLQuery.Operator.lessThan.description, "<")
        XCTAssertEqual(SQLQuery.Operator.greaterThan.description, ">")
        XCTAssertEqual(SQLQuery.Operator.lessThanOrEqualTo.description, "<=")
        XCTAssertEqual(SQLQuery.Operator.greaterThanOrEqualTo.description, ">=")
        XCTAssertEqual(SQLQuery.Operator.notEqualTo.description, "!=")
        XCTAssertEqual(SQLQuery.Operator.like.description, "LIKE")
        XCTAssertEqual(SQLQuery.Operator.notLike.description, "NOT LIKE")
        XCTAssertEqual(SQLQuery.Operator.raw("foo").description, "foo")
    }
}
