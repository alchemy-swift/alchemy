@testable
import Alchemy
import XCTest

final class SQLUtilitiesTests: XCTestCase {
    func testJoined() {
        XCTAssertEqual([
            SQL("where foo = ?", bindings: [.int(1)]),
            SQL("bar"),
            SQL("where baz = ?", bindings: [.string("two")])
        ].joinedSQL(), SQL("where foo = ? bar where baz = ?", bindings: [.int(1), .string("two")]))
    }
    
    func testDropLeadingBoolean() {
        XCTAssertEqual(SQL("foo").droppingLeadingBoolean().statement, "foo")
        XCTAssertEqual(SQL("and bar").droppingLeadingBoolean().statement, "bar")
        XCTAssertEqual(SQL("or baz").droppingLeadingBoolean().statement, "baz")
    }
}
