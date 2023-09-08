import Alchemy
import XCTest

final class SQLTests: XCTestCase {
    func testValueConvertible() {
        let sql: SQL = "NOW()"
        XCTAssertEqual(sql.rawSQLString, "NOW()")
    }

    func testJoined() {
        XCTAssertEqual([
            SQL("where foo = ?", parameters: [.int(1)]),
            SQL("bar"),
            SQL("where baz = ?", parameters: [.string("two")])
        ].joined(), SQL("where foo = ? bar where baz = ?", parameters: [.int(1), .string("two")]))
    }
}
