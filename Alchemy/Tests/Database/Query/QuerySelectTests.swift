@testable
import Alchemy
import AlchemyTesting

struct QuerySelectTests {
    @Test func startsEmpty() {
        let query = TestQuery("foo")
        #expect(query.table == "foo")
        #expect(query.columns == ["*"])
        #expect(query.isDistinct == false)
        #expect(query.limit == nil)
        #expect(query.offset == nil)
        #expect(query.lock == nil)
        #expect(query.joins == [])
        #expect(query.wheres == [])
        #expect(query.groups == [])
        #expect(query.havings == [])
        #expect(query.orders == [])
    }

    @Test func select() {
        let specific = TestQuery("foo").select(["bar", "baz"])
        #expect(specific.columns == ["bar", "baz"])
        let all = TestQuery("foo").select()
        #expect(all.columns == ["*"])
    }

    @Test func distinct() {
        #expect(TestQuery("foo").distinct().isDistinct == true)
    }
}
