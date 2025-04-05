@testable
import Alchemy
import AlchemyTesting

struct QueryJoinTests {
    @Test func join() {
        let query = TestQuery("foo").join(table: "bar", first: "id1", second: "id2")
        #expect(query.joins == [sampleJoin(of: .inner)])
        #expect(query.wheres == [])
    }

    @Test func leftJoin() {
        let query = TestQuery("foo").leftJoin(table: "bar", first: "id1", second: "id2")
        #expect(query.joins == [sampleJoin(of: .left)])
        #expect(query.wheres == [])
    }

    @Test func rightJoin() {
        let query = TestQuery("foo").rightJoin(table: "bar", first: "id1", second: "id2")
        #expect(query.joins == [sampleJoin(of: .right)])
        #expect(query.wheres == [])
    }

    @Test func crossJoin() {
        let query = TestQuery("foo").crossJoin(table: "bar", first: "id1", second: "id2")
        #expect(query.joins == [sampleJoin(of: .cross)])
        #expect(query.wheres == [])
    }

    @Test func on() {
        let query = TestQuery("foo").join(table: "bar") {
            $0.on(first: "id1", op: .equals, second: "id2")
                .orOn(first: "id3", op: .greaterThan, second: "id4")
        }

        var expectedJoin = SQLJoin(type: .inner, joinTable: "bar")
        expectedJoin.wheres = [
            SQLWhere(boolean: .and, clause: .column(column: "id1", op: .equals, otherColumn: "id2")),
            SQLWhere(boolean: .or, clause: .column(column: "id3", op: .greaterThan, otherColumn: "id4"))
        ]

        #expect(query.joins == [expectedJoin])
        #expect(query.wheres == [])
    }

    @Test func equality() {
        #expect(sampleJoin(of: .inner) == sampleJoin(of: .inner))
        #expect(sampleJoin(of: .inner) != sampleJoin(of: .cross))
        #expect(sampleJoin(of: .inner).table != "foo")
    }

    private func sampleJoin(of type: SQLJoin.JoinType) -> SQLJoin {
        return SQLJoin(type: type, joinTable: "bar")
            .on(first: "id1", op: .equals, second: "id2")
    }
}
