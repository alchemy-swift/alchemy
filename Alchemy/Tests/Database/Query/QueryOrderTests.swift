@testable
import Alchemy
import AlchemyTesting

struct QueryOrderTests {
    @Test func orderBy() {
        let query = TestQuery("foo")
            .orderBy("bar")
            .orderBy("baz", direction: .desc)
        #expect(query.orders == [
            SQLOrder(column: "bar", direction: .asc),
            SQLOrder(column: "baz", direction: .desc),
        ])
    }
}
