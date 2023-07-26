import Alchemy
import XCTest

final class SQLParameterConvertibleTests: XCTestCase {
    func testRawSQLString() {
        let jsonString = """
        {"foo":"bar"}
        """
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        XCTAssertEqual(SQLValue.json(jsonData).rawSQLString, "'\(jsonString)'")
        XCTAssertEqual(SQLValue.null.rawSQLString, "NULL")
        XCTAssertEqual(SQLValue.string("foo").rawSQLString, "'foo'")
    }
}
