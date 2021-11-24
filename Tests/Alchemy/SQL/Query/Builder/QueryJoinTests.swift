@testable
import Alchemy
import AlchemyTest

final class QueryJoinTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.stub()
    }
    
    func testJoin() {
        let query = Database.table("foo").join(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .inner)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testLeftJoin() {
        let query = Database.table("foo").leftJoin(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .left)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testRightJoin() {
        let query = Database.table("foo").rightJoin(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .right)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testCrossJoin() {
        let query = Database.table("foo").crossJoin(table: "bar", first: "id1", second: "id2")
        XCTAssertEqual(query.joins, [sampleJoin(of: .cross)])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testOn() {
        let query = Database.table("foo").join(table: "bar") {
            $0.on(first: "id1", op: .equals, second: "id2")
                .orOn(first: "id3", op: .greaterThan, second: "id4")
        }
        
        let expectedJoin = Query.Join(database: Database.default.driver, table: "foo", type: .inner, joinTable: "bar")
        expectedJoin.joinWheres = [
            Query.Where(type: .column(first: "id1", op: .equals, second: "id2"), boolean: .and),
            Query.Where(type: .column(first: "id3", op: .greaterThan, second: "id4"), boolean: .or)
        ]
        XCTAssertEqual(query.joins, [expectedJoin])
        XCTAssertEqual(query.wheres, [])
    }
    
    func testEquality() {
        XCTAssertEqual(sampleJoin(of: .inner), sampleJoin(of: .inner))
        XCTAssertNotEqual(sampleJoin(of: .inner), sampleJoin(of: .cross))
        XCTAssertNotEqual(sampleJoin(of: .inner), Database.table("foo"))
    }
    
    private func sampleJoin(of type: Query.JoinType) -> Query.Join {
        return Query.Join(database: Database.default.driver, table: "foo", type: type, joinTable: "bar")
            .on(first: "id1", op: .equals, second: "id2")
    }
}
