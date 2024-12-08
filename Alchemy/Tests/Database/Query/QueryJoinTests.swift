@testable
import Alchemy
import AlchemyTesting

final class QueryJoinTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        DB.stub()
    }
    
    func testJoin() {
        let query = DB.table("foo").join(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .inner)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testLeftJoin() {
        let query = DB.table("foo").leftJoin(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .left)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testRightJoin() {
        let query = DB.table("foo").rightJoin(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .right)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testCrossJoin() {
        let query = DB.table("foo").crossJoin(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .cross)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testOn() {
        let query = DB.table("foo").join(table: "bar") {
            $0.on(first: "id1", op: .equals, second: "id2")
                .orOn(first: "id3", op: .greaterThan, second: "id4")
        }
        
        var expectedJoin = SQLJoin(type: .inner, joinTable: "bar")
        expectedJoin.wheres = [
            SQLWhere(boolean: .and, clause: .column(column: "id1", op: .equals, otherColumn: "id2")),
            SQLWhere(boolean: .or, clause: .column(column: "id3", op: .greaterThan, otherColumn: "id4"))
        ]

        XCTAssertEqual(query.joins, [expectedJoin])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testEquality() {
        XCTAssertEqual(sampleJoin(of: .inner), sampleJoin(of: .inner))
        XCTAssertNotEqual(sampleJoin(of: .inner), sampleJoin(of: .cross))
        XCTAssertNotEqual(sampleJoin(of: .inner).table, "foo")
    }
    
    private func sampleJoin(of type: SQLJoin.JoinType) -> SQLJoin {
        return SQLJoin(type: type, joinTable: "bar")
            .on(first: "id1", op: .equals, second: "id2")
    }
}
