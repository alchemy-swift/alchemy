import Alchemy
import XCTest

final class SQLValueConvertibleTests: XCTestCase {
    func testRawSQLString() {
        let jsonString = """
        {"foo":"bar"}
        """
        let bytes = ByteBuffer(data: jsonString.data(using: .utf8) ?? Data())
        XCTAssertEqual(SQLValue.json(bytes).rawSQLString, "\(jsonString)")
        XCTAssertEqual(SQLValue.null.rawSQLString, "NULL")
        XCTAssertEqual(SQLValue.string("foo").rawSQLString, "'foo'")
    }
}
