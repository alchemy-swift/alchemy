@testable
import Alchemy
import AlchemyTesting

struct QueryGroupingTests {
    let sampleWhere = SQLWhere.and(.value(column: "id", op: .equals, value: .value(.int(1))))

    @Test func groupBy() {
        #expect(TestQuery("foo").groupBy("bar").groups == ["bar"])
        #expect(TestQuery("foo").groupBy("bar").groupBy("baz").groups == ["bar", "baz"])
    }
    
    @Test func having() {
        let orWhere = SQLWhere.or(sampleWhere.clause)
        let query = TestQuery("foo")
            .having(sampleWhere.clause)
            .orHaving(orWhere.clause)
            .orHaving("bar", .like, "baz")
        #expect(query.havings == [
            sampleWhere,
            orWhere,
            SQLWhere.or(.value(column: "bar", op: .like, value: .value(.string("baz"))))
        ])
    }
}
