@testable
import Alchemy
import AlchemyTest

final class QueryOperatorTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testOperatorDescriptions() {
        XCTAssertEqual(SQLWhere.Operator.equals.description, "=")
        XCTAssertEqual(SQLWhere.Operator.lessThan.description, "<")
        XCTAssertEqual(SQLWhere.Operator.greaterThan.description, ">")
        XCTAssertEqual(SQLWhere.Operator.lessThanOrEqualTo.description, "<=")
        XCTAssertEqual(SQLWhere.Operator.greaterThanOrEqualTo.description, ">=")
        XCTAssertEqual(SQLWhere.Operator.notEqualTo.description, "!=")
        XCTAssertEqual(SQLWhere.Operator.like.description, "LIKE")
        XCTAssertEqual(SQLWhere.Operator.notLike.description, "NOT LIKE")
        XCTAssertEqual(SQLWhere.Operator.raw("foo").description, "foo")
    }
}
