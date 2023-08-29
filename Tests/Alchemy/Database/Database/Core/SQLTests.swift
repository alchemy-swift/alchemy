import Alchemy
import XCTest

final class SQLTests: XCTestCase {
    func testValueConvertible() {
        let sql: SQL = "NOW()"
        XCTAssertEqual(sql.rawSQLString, "NOW()")
    }
}
