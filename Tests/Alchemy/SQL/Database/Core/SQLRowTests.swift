@testable
import Alchemy
import AlchemyTest

final class SQLRowTests: XCTestCase {
    func testDecode() {
        struct Test: Model, Equatable {
            var id: Int?
            let foo: Int
            let bar: String
        }
        
        let row: SQLRow = StubDatabaseRow(data: ["foo": 1, "bar": "two"])
        XCTAssertEqual(try row.decode(Test.self), Test(foo: 1, bar: "two"))
    }
    
    func testSubscript() {
        let row: SQLRow = StubDatabaseRow(data: ["foo": 1])
        XCTAssertEqual(row["foo"], .int(1))
        XCTAssertEqual(row["bar"], nil)
    }
}
