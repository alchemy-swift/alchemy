import Alchemy
import XCTest

final class SQLValueConvertibleTests: XCTestCase {
    func testValueLiteral() {
        let jsonString = """
        {"foo":"bar"}
        """
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        XCTAssertEqual(SQLValue.json(jsonData).sqlLiteral, "'\(jsonString)'")
        XCTAssertEqual(SQLValue.null.sqlLiteral, "NULL")
    }
    
    func testSQL() {
        XCTAssertEqual(SQLValue.string("foo").sql, SQL("'foo'"))
        XCTAssertEqual(SQL("foo", bindings: [.string("bar")]).sql, SQL("foo", bindings: [.string("bar")]))
    }
}
