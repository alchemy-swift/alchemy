@testable
import Alchemy
import AlchemyTest

final class QueryOperatorTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testOperatorDescriptions() {
        XCTAssertEqual(Query.Operator.equals.description, "=")
        XCTAssertEqual(Query.Operator.lessThan.description, "<")
        XCTAssertEqual(Query.Operator.greaterThan.description, ">")
        XCTAssertEqual(Query.Operator.lessThanOrEqualTo.description, "<=")
        XCTAssertEqual(Query.Operator.greaterThanOrEqualTo.description, ">=")
        XCTAssertEqual(Query.Operator.notEqualTo.description, "!=")
        XCTAssertEqual(Query.Operator.like.description, "LIKE")
        XCTAssertEqual(Query.Operator.notLike.description, "NOT LIKE")
        XCTAssertEqual(Query.Operator.raw("foo").description, "foo")
    }
}
